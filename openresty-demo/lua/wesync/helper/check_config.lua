--
-- check config lua module if need reload
-- check config.lua need reload
--

local ngx_log = ngx.log
local DEBUG = ngx.DEBUG
local INFO = ngx.INFO
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local tool = require "wesync.tool"
local ngw_log = require "wesync.ngw_log"

local exiting = ngx.worker.exiting
local exit = ngx.exit
local new_timer = ngx.timer.at

local delay = 5
local config = require "wesync.config"
local dync_config = require "wesync.helper.dync_config"

local _M = {}

local function handle_dync_config(dict)
    dict = dict or ngx.shared.http_dync_confs
    local str, _ = dync_config.get_directive(dict)
    -- 若忘记填写新增的Consul Key&Value情况下，这时 wesync/config.lua 所填写内容更为完整。这时需要保持兼容性
    if not str then
        local lm = "dync.config"
        local olt = package.loaded[lm]
        if olt then
            return
        end

        pcall(require, lm)
        olt = package.loaded[lm]
        if olt then
            local num = dync_config.fill_wesync_config(olt)
            ngx_log(INFO, "prepare reload module: " .. lm .. " with set changed value result: " .. num)
        end

        return
    end

    ngx_log(DEBUG, "read dync config directive: " .. str)
    -- 格式：wesync.config version
    local arr = tool.split(str, " ")
    local lm = arr[1]
    local lv = arr[2]
    local olt = package.loaded[lm]

    if not olt then
        pcall(require, lm)
        olt = package.loaded[lm]

        if olt then
            local num = dync_config.fill_wesync_config(package.loaded[lm])
            ngx_log(INFO, "reload module: " .. str .. " with set changed value result: " .. num)
            return
        end
    end

    if not olt then
        ngx_log(CRIT, lm .. " load failure !!!")
        ngw_log.log(CRIT, lm .. " load failure !!!")
        return
    end

    if olt._VERSION == lv or config._VERSION == lv then
        ngx_log(DEBUG, "has same version: " .. lv)
        return
    end

    if olt._VERSION == lv then
        return
    end

    ngx_log(INFO, "need reload module: " .. lm .. " with new version: " .. lv .. ", and existing version: " .. olt._VERSION .. ", and table: " .. tostring(olt))
    package.loaded[lm] = nil
    -- 卸载，然后再次加载，若加载失败，需要恢复原先已加载实例
    local success, _ = pcall(require, lm)
    if not success then
        ngx_log(CRIT, lm .. " reload failure with code reload_lua_failure !")
        ngw_log.log(CRIT, lm .. " reload failure with code reload_lua_failure !")
        package.loaded[lm] = olt
    else
        local num = dync_config.fill_wesync_config(package.loaded[lm])
        ngx_log(INFO, "reload module: " .. str .. " with result: " .. num)
    end

    -- 在dev私有开发环境中，擅自改动 dync/config.lua 模块，会导致重复多次判断版本号，需要添加兼容
    if config.test_env and olt._VERSION ~= lv then
        olt._VERSION = lv
        config._VERSION = lv
    end
end

-- TCP 和 HTTP稍微有区别
function _M.check_conf_tcp(premature)
    if premature then
        return
    end

    while true do
        if exiting() then
            exit(0)
        end

        handle_dync_config()

        ngx.sleep(delay)
    end

    -- new_timer(delay, _M.check_conf_tcp)
end

function _M.check_conf_http(premature, dict)
    if premature then
        return
    end

    if exiting() then
        exit(0)
    end

    dict = dict or ngx.shared.http_dync_confs
    handle_dync_config(dict)

    new_timer(delay, _M.check_conf_http, dict)
end

-- function _M.start_check_conf_tcp(premature)
--     ngx.thread.spawn(_M.check_conf_tcp)
-- end

return _M
