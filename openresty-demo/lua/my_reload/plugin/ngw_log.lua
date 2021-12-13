local _M = {}

local logger = require "resty.logger.socket"
local ngx_log = ngx.log
local config = require "wesync.config"
local cjson = require "cjson"
local DEBUG = ngx.DEBUG
local INFO = ngx.INFO
local NOTICE = ngx.NOTICE
local WARN = ngx.WARN
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local ALERT = ngx.ALERT
local VIPLOG = "vip_log"
local table_concat = table.concat
local table_insert = table.insert
local table_clear = require "table.clear"
local succ, table_new = pcall(require, "table.new")
if not succ then
    table_new = function() return {} end
end

local loglevel = {
    [DEBUG] = "[debug] ",
    [INFO] = "[info] ",
    [NOTICE] = "[notice] ",
    [WARN] = "[warn] ",
    [ERR] = "[error] ",
    [CRIT] = "[crit] ",
    [ALERT] = "[alert] ",
    [VIPLOG] = "[vip_log] "
}
local maxCounters = 10
local counters = table_new(maxCounters, 0)
local function do_log(msg)
    if not logger.initted() then
        _M.init_log()
    end

    local droplimit = config.drop_limit
    if #msg >= droplimit then
        local droplimit_sub = droplimit - 1
        msg = string.sub(msg, 1, droplimit_sub)
    end
    msg = msg .. "\n"

    local _, err = logger.log(msg)
    if err then
        ngx_log(ERR, "failed to log message: ", err)
    end
end

local function write_log(log, level, uid)
    local prefix
    if uid then
        uid = tostring(uid)

        local dync_config = require "wesync.config"
        local nickname = dync_config.vip_users[uid]
        if nickname then
            prefix = string.format("[vip_log](%s, %s) ", uid, nickname)
            log = prefix .. log
        end
    end

    if config.test_env then
        level = level or INFO
        return ngx_log(level, log)
    end

    if not level then
        return do_log(log)
    end

    if prefix then
        return do_log(loglevel[level] .. log)
    end

    if level <= config.logFilter then
        do_log(loglevel[level] .. log)
    end
end

function _M.init_log()
    ngx_log(ERR, "init logger")
    local ok, err = logger.init {
        host = config.syslog_ng_host,
        port = config.syslog_ng_log_port,
        flush_limit = config.flush_limit,
        drop_limit = config.drop_limit,
        periodic_flush = config.periodic_flush,
        sock_type = config.sock_type
    }
    if not ok then
        ngx_log(ERR, "failer to initialize the logger: ", err)
    end
end

function _M.comp_cost_time(et, st, needc)
    -- 变成整数，避免浮点数运算后面添加小数点
    et = et or 1
    st = st or 1
    local timeCost = et * 1000 - st * 1000

    needc = needc or false
    local tcs = ""

    if needc then
        if timeCost <= 50 then
            tcs = "lt_50ms"
        elseif timeCost <= 100 then
            tcs = "lt_100ms"
        elseif timeCost <= 200 then
            tcs = "lt_200ms"
        elseif timeCost <= 500 then
            tcs = "lt_500ms"
        elseif timeCost > 500 then
            tcs = "gt_500ms"
        end
    end

    return tcs, timeCost
end

-- 计数器
function _M.inc(keyWord)
    if config.test_env then
        local msg = "neo_counter: " .. keyWord
        ngx_log(NOTICE, msg)
    else
        if #counters < maxCounters then
            counters[#counters + 1] = keyWord
        else
            local msg = "neo_counter: " .. table_concat(counters, ",")
            do_log(msg)
            counters = table_new(maxCounters, 0)
        end
    end
end

function _M.log(level, msg, uid)
    write_log(msg, level, uid)
end

function _M.log_inc(level, keyWord, msg, uid)
    local msg = _M.generate_msg({ msg, ", neo_counter: ", keyWord }, "")
    write_log(msg, level, uid)
end

function _M.log_time(recv_client, send_server, recv_server, send_client)
    local msg = _M.generate_msg({ "time_cost: ", recv_client, send_server, recv_server, send_client })
    write_log(msg, NOTICE)
end

local function log_special_proxy(sproxy, total_ms, proxy_ms, backend_ms)
    local errcode = sproxy.errcode
    local request_bytes = sproxy.request_bytes or 0
    local response_bytes = sproxy.response_bytes or 0
    -- 记录请求的各个耗时
    local omsg = string.format("special_proxy request_id: %s, url: %s, method: %s, parameters: %s with total_cost: %d, proxy_cost: %d, backend_cost: %d, and errmsg: %s, errcode: %s, client_ip: %s, request_bytes: %d, response_bytes: %d",
        sproxy.request_id, sproxy.raddr, sproxy.method, sproxy.parameters, total_ms, proxy_ms, backend_ms, sproxy.errmsg, errcode, ngx.var.remote_addr, request_bytes, response_bytes)

    local inct = table_new(7, 0)

    local status = sproxy.status
    local types = sproxy.rtype or 'nil'

    if status then
        -- 记录响应状态码，对应单个接口的HTTP Status业务状态码
        table_insert(inct, "proxy_resp_" .. status)
        -- eg: repost_timeline_resp_200
        table_insert(inct, types .. "_resp_" .. status)

        if status == 200 then
            -- 为每一个业务接口耗时做计数
            table_insert(inct, sproxy.rtype .. "|" .. backend_ms)
            table_insert(inct, "proxy_" .. types .. "|" .. proxy_ms)
            table_insert(inct, "total_" .. types .. "|" .. total_ms)
        end
    end

    -- 为业务端返回的业务错误代码添加计数
    if errcode ~= "nil" and errcode ~= nil then
        table_insert(inct, "backend_errcode")
        table_insert(inct, types .. "_errcode")
    end

    local msg = table_concat { omsg, ", neo_counter: ", table_concat(inct, ",") }
    table_clear(inct)

    return msg
end

-- 记录透明代理耗费时间
local function log_direct_proxy(dproxy, total_ms, proxy_ms)
    --local _, total_ms = _M.comp_cost_time(send_client, recv_client)
    --local _, proxy_ms = _M.comp_cost_time(recv_server, send_server)
    local errcode = dproxy.errcode
    local errmsg = dproxy.errmsg
    local status = dproxy.status
    local rtype = dproxy.rtype
    local raddr = dproxy.raddr
    local request_id = dproxy.request_id
    local method = dproxy.method
    local parameters = dproxy.parameters
    local request_bytes = dproxy.request_bytes or 0
    local response_bytes = dproxy.response_bytes or 0

    -- 记录请求的各个耗时
    local omsg = string.format("direct_proxy request_id: %s, url: %s, method: %s, parameters: %s with total_cost: %d, proxy_cost: %d, and errmsg: %s, errcode: %s, client_ip: %s, request_bytes: %d, response_bytes: %d",
        request_id, raddr, method, parameters, total_ms, proxy_ms, errmsg, errcode, ngx.var.remote_addr, request_bytes, response_bytes)

    local inct = table_new(5, 0)

    if status then
        -- 记录响应状态码，已经单个接口的业务状态码
        table_insert(inct, "dproxy_resp_" .. status)
        -- eg: repost_timeline_resp_200
        table_insert(inct, rtype .. "_resp_" .. status)

        if status == 200 then
            table_insert(inct, "dproxy|" .. proxy_ms)
            table_insert(inct, rtype .. "|" .. proxy_ms)
            table_insert(inct, "total_" .. rtype .. "|" .. total_ms)
        end
    end

    -- 为业务端返回的业务错误代码添加计数
    if errcode ~= "nil" and errcode ~= nil then
        table_insert(inct, rtype .. "_errcode")
        -- 统一记录透明代理业务层面错误代码计数
        table_insert(inct, "dproxy_resp_errcode")
    end

    local msg = _M.generate_msg({ omsg, ", neo_counter: ", table_concat(inct, ",") }, '')

    table_clear(inct)

    return msg
end

-- 专门用于记录聚合接口，每一操作步骤详细耗时
-- eg：handle http://i.api.weibo.cn/2/statuses/unread_friends_timeline?... with total_cost: 204, proxy_cost: 201, backend_cost: 190, and errmsg: nil, neo_counter: friends_timeline,backend_lt_200ms,friends_timeline_lt_200ms,proxy_resp_200,friends_timeline_resp_200,total_friends_timeline_lt_500ms,proxy_friends_timeline_lt_500ms while handling client connection ...
function _M.log_proxy(user, recv_client, send_server, recv_server, send_client)
    local proxy = user.proxy
    local uid = user.uid or ""
    local ljson = user.log_json or {}

    local msg
    local proxy_type = proxy.ptype
    local errcode = proxy.errcode
    local proxy_path = proxy.proxy_path
    local dync_config = require "wesync.config"

    if proxy_path then
        if dync_config.filter_proxy_paths[proxy_path] then
            ljson.need_trace = true
        end
    end
    local need_trace = ljson.need_trace or false

    ljson.proxy_type = proxy_type
    ljson.status = proxy.status
    ljson.errcode = proxy.errcode
    ljson.errmsg = proxy.errmsg

    if proxy_type == 'special_proxy' then
        local _, total_ms = _M.comp_cost_time(send_client, recv_client)
        local _, backend_ms = _M.comp_cost_time(proxy.resp_time, proxy.req_time)
        local _, proxy_ms = _M.comp_cost_time(recv_server, send_server)

        ljson.handle_time = total_ms
        ljson.backend_time = backend_ms

        msg = log_special_proxy(proxy, total_ms, proxy_ms, backend_ms)
    else
        local _, total_ms = _M.comp_cost_time(send_client, recv_client)
        local _, proxy_ms = _M.comp_cost_time(recv_server, send_server)

        ljson.handle_time = total_ms
        ljson.backend_time = proxy_ms

        msg = log_direct_proxy(proxy, total_ms, proxy_ms)
    end

    uid = tostring(uid)
    local nickname = dync_config.vip_users[uid]

    local level = INFO

    local jstr = cjson.encode(ljson)

    local jsonstr
    if need_trace then
        jsonstr = table_concat({ '|', jstr, '|' })
    else
        jsonstr = jstr
    end

    if not nickname then
        write_log(msg, level)
        write_log(jsonstr, level)

        return
    end

    local prefix
    local request_id = ljson.request_id
    if not request_id then
        request_id = proxy.request_id
    end

    if request_id then
        prefix = string.format("[vip_log](%s, %s) request_id: %s ", uid, nickname, request_id)
    else
        prefix = string.format("[vip_log](%s, %s) ", uid, nickname)
    end

    -- 记录聚合接口的统计信息
    if errcode ~= "nil" and errcode ~= nil then
        write_log(table_concat({ prefix, msg }), ERR)
    else
        write_log(table_concat({ prefix, msg }), level)
    end

    -- 记录请求的原始信息
    local response = proxy.response
    write_log(table_concat({ prefix, jsonstr }), level)

    -- 只有VIP用户才会主动记录响应内容
    -- 响应太大的话，若与请求合并输出可能会被自动截断，采取折中方式
    -- TODO 合并 ？
    if response then
        local resp_log = { prefix, "response header: ", cjson.encode(response[1]), ", response body: ", cjson.encode(response[2]) }
        write_log(table_concat(resp_log), level)
    end
end

function _M.interface_log(msg)
    if "string" == type(msg) then
        if config.test_env then
            ngx_log(NOTICE, "ngw_interfact_log: " .. msg)
        else
            do_log("interfact:" .. msg)
        end
    end
end

function _M.generate_msg(params, sep)
    if not sep then
        sep = ","
    end
    local msg = table_concat(params, sep)
    return msg
end

return _M
