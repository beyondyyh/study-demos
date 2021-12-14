local ngx_log = ngx.log
local INFO = ngx.INFO
local CRIT = ngx.CRIT

local delay_send = require "wesync.plugin.common".delay_send

local _M = {}

local inited = false

-- 默认需要加载插件列表，若 consul中被设置，对应键值对内容会被覆盖
local default_plugins = {
    ["wesync.plugin.check_config"] = true,
}

local function sortf(a, b)
    return a.priority < b.priority
end

local function get_err_resp(code, header)
    -- local h = wesync.header()
    -- h.proto = 63

    -- if header then
    --     h.request_tid = header.tid
    --     h.request_id = header.request_id
    -- end

    -- local body = wesync.gen_resp()
    -- body.code = code

    -- return h, body
    return header, {code = code, error_msg = "something wrong!"}
end

local function get_mn(mn)
    if string.find(mn, "wesync.") then
        return mn
    else
        return "wesync.plugin." .. mn
    end
end

local function log_crit(logstr)
    ngx_log(CRIT, logstr)
end

-- 插件实例数组
local plugins = {}

function _M:add_plugin(mn)
    local lmodule = get_mn(mn)

    local succ, lmod = pcall(require, lmodule)
    if not succ then
        log_crit("load " .. lmodule .. " got error: " .. tostring(lmod))
        return succ, lmod
    end

    local need_add = true
    for _, v in ipairs(plugins) do
        if lmod.name == v.name then
            need_add = false
            break
        end
    end

    if not need_add then
        return false, 'had existing ' .. lmodule
    end

    local succ2, lobj = pcall(lmod.new, lmod)

    if not succ2 then
        log_crit("call " .. lmodule .. ":new() got error: " .. lobj)
        return succ2, lobj
    end

    if not lobj then
        log_crit("call " .. lmodule .. ":new() got nil distance nil")
        return false, lmodule .. ':new() return nil'
    end


    if inited then
        ngx_log(INFO, "call " .. lmodule .. " distance's init_worker() method now ......")
        local succ3, tmp = pcall(lobj.init_worker, lobj)

        if not succ3 then
            log_crit("call " .. lmodule .. ":init_worker() got error: " .. tmp)
            return false, tmp
        end
    end

    ngx_log(ngx.ALERT, 'add plugin: ' .. lmodule)
    table.insert(plugins, lobj)

    if inited then
        -- 排序，按照优先级次序，数值低的排到前面位置，数值高的说明优先级低，按照从低到高排列
        table.sort(plugins, sortf)
    end

    return true
end

function _M:del_plugin(mn)
    local lmodule = get_mn(mn)
    local succ, lmod = pcall(require, lmodule)
    if not succ then
        log_crit("load " .. lmodule .. " got error: " .. tostring(lmod))
        return succ, lmod
    end

    local success = false
    for i, v in ipairs(plugins) do
        if lmod.name == v.name then
            table.remove(plugins, i)
            v:uninstall()
            ngx_log(ngx.ALERT, 'del plugin: ' .. lmodule)
            success = true
            break
        end
    end

    return success
end

-- 重新加载插件
function _M:reload_plugin(mn)
    local success, err = _M:del_plugin(mn)

    if not success then
        return success, err
    end

    local lm = get_mn(mn)
    package.loaded[lm] = nil
    local succ2, err2 = _M:add_plugin(mn)
    ngx.log(ngx.ALERT, 'reload plugin: ' .. mn .. ', result: ' .. tostring(succ2))

    return succ2, err2
end

function _M:get_plugins()
    return plugins
end

function _M:access_phases(ctx)
    for _, p in ipairs(plugins) do
        if not ctx.delayed_response then
            local succ, lerr = pcall(p.access, p, ctx) -- p:access(ctx)
            if not succ then
                log_crit("plugin call " .. p.name .. ":access(ctx) got error: " .. tostring(lerr))

                if p.break_on_error then
                    if ctx.delayed_response then
                        break
                    end

                    delay_send(ctx, 1033, ctx.req.header)
                    break
                end
            end
        end
    end

    if ctx.delayed_response then
        local dc = ctx.delay_content
        ctx.delayed_response = false
        ngx_log(INFO, "delayed_response", "with code: " .. dc[1])
        ctx.delayed_content = { dc[1], get_err_resp(dc[1], dc[2]) }
        ctx.delay_content = nil
    end
end

function _M:log_phases(ctx)
    for _, p in ipairs(plugins) do
        local succ, lerr = pcall(p.log, p, ctx) -- p:log(ctx)
        if not succ then
            log_crit("plugin call " .. p.name .. ":log(ctx) got error: " .. tostring(lerr))
        end
    end
end

-- 或许支持只需要后台运行的插件支持 ？
function _M:init_phases(ctx)
    for _, p in ipairs(plugins) do
        local succ, lerr = pcall(p.init_worker, p, ctx) -- p:init_worker(ctx)
        if not succ then
            log_crit("plugin call " .. p.name .. ":init_worker(ctx) got error: " .. tostring(lerr))
        end
    end

    inited = true
end

-- 通过读取配置文件，加载、或删除插件
local function init_plugins()
    local config = require "wesync.config"
    local __plugins = config.plugins
    local _plugins
    if not __plugins then
        if inited then
            return
        end
        _plugins = default_plugins
    else
        _plugins = {}
        -- 避免污染到config值
        for k, v in pairs(__plugins) do
            _plugins[k] = v
        end
    end

    -- 在初始化该模块时，这里处理默认插件以及已配置插件，两者合并到一起
    -- 为了避免忘记在Consul中忘记设置某一个插件导致加载不上，采取策略consul中所配置是作为一种补充和延伸
    if not inited and __plugins then
        for k, v in pairs(default_plugins) do
            if not _plugins[k] then
                _plugins[k] = v
            end
        end
    end

    for k, v in pairs(_plugins) do
        if v == false then
            _M:del_plugin(k)
        elseif v == 'reload' then
            _M:reload_plugin(k)
        else
            _M:add_plugin(k)
        end
    end
end

function _M:init_plugins()
    init_plugins()
end

init_plugins()

return _M