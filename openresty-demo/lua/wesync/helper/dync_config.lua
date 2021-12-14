--
-- 动态操作工具
--

local match = ngx.re.match
local ngx_log = ngx.log
local INFO = ngx.INFO
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = { _VERSION = '0.1' }

_M.key = "reload_lua"
local config = require "wesync.config"
local dconf = require "dync.config"

local cmds = {}

local function do_reload(dict, lm, lv)
    local val = lm .. " " .. lv
    ngx_log(INFO, "ngx.shared.dict set with key: " .. _M.key .. ", value: " .. val)
    local success, err, _ = dict:set(_M.key, val)
    if not success then
        ngx_log(CRIT, "ngx.shared.dict set with key: " .. _M.key .. ", value: " .. val .. " got error: " .. err)
        return false, err
    end

    return true, nil
end

local function do_getver(_, lm, _)
    local olt = package.loaded[lm]

    if not olt then
        return false, "load failed"
    end

    return true, olt._VERSION
end

local function do_getconf(_, lm, _)
    local olt = package.loaded[lm]
    if not olt then
        return false, "load failed"
    end

    local t = {}

    for k, v in pairs(olt) do
        table.insert(t, k .. " = " .. tostring(v))
    end

    table.insert(t, "module info: " .. tostring(olt))
    table.insert(t, "the reloaded config module info: " .. tostring(config))
    -- table.insert(t, "the reloaded config's syslog_ng_host: " .. config.syslog_ng_host)

    return true, table.concat(t, "\n")
end

local function do_testreg(_, _, v)
    local config = require "wesync.config"
    local m, err = match(v, config.uid_grey, "jo")

    if not m then
        if err then
            ngx_log(CRIT, "analyse ori: " .. v .. " got error: " .. err)
        end
        return false, "not match"
    end

    return true, "matched !"
end

cmds["config"] = do_reload
cmds["reload"] = do_reload
cmds["getver"] = do_getver
cmds["getconf"] = do_getconf
cmds["testreg"] = do_testreg

-- 根据指令类型进行分发业务
function _M.handle_directive(dict, ori)
    local m, err = match(ori, "\\s*(.*) (.*) (.*)", "jo")

    if not m then
        ngx_log(CRIT, "analyse ori: " .. ori .. " got error: " .. err)
        return
    end

    return cmds[m[1]](dict, m[2], m[3])
end

function _M.get_directive(dict)
    local str, err = dict:get(_M.key)
    if not str and err then
        ngx_log(INFO, "ngx.shared.dict get by key: " .. _M.key .. " got error: " .. tostring(err))
    end

    return str, err
end

local dync_plugins = {
    keys = {
        plugins = true
    },
    changed = false,
    callback = function()
        ngx_log(INFO, "phases init plugins now ...")
        local phases = require "wesync.plugin.phases"
        phases.init_plugins()
    end
}

-- 所有需要再次初始化都需要在这里进行注册
local all_confs = {
    -- syslog_confs,
    -- redis_confs,
    dync_plugins
}

local function check_changed(k)
    for _, v in ipairs(all_confs) do
        local keys = v.keys

        if keys[k] then
            v.changed = true
        end
    end
end

local function changed_callback()
    for _, v in ipairs(all_confs) do
        if v.changed then
            v.callback()
            v.changed = false
        end
    end
end

function _M.fill_wesync_config(newcfg)
    if not newcfg or newcfg == true then
        ngx_log(ERR, "invalid dync.config ! ")
        return -1
    end

    local num = 0
    local is_equal = require("wesync.compare").is_equal

    if not dconf then
        dconf = config
    end

    for k, v in pairs(newcfg) do
        if k ~= '_VERSION' and not is_equal(dconf[k], v) then
            dconf[k] = v
            ngx_log(INFO, "set wesync.config with " .. k .. ": " .. tostring(v))
            num = num + 1

            check_changed(k)
        end
    end

    if newcfg._VERSION ~= config._VERSION then
        config._VERSION = newcfg._VERSION
    end

    changed_callback()

    return num
end

return _M