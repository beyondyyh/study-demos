--
-- check config lua module if need reload
-- check config.lua need reload
--

local ngx_log = ngx.log
local DEBUG = ngx.DEBUG
local INFO = ngx.INFO
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local subsys = ngx.config.subsystem

local bo = require "wesync.plugin.base_plugin"
local tool = require "common.tool"

local exiting = ngx.worker.exiting
local exit = ngx.exit
local timer_at = ngx.timer.at

local delay = 5
local config = require "wesync.config"
local dync_config = require "wesync.helper.dync_config"

local _M = bo:extend()

local dict
if subsys == 'http' then
    dict = ngx.shared.http_dync_confs
else
    dict = ngx.shared.dync_confs
end

_M.name = "check_config"

local function handle_dync_config()
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
    -- 格式：dync.config version，例如：dync.config 0.04
    local arr = tool.split(str, " ")
    local lm = arr[1] -- load module name
    local lv = arr[2] -- load module version
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

function _M:check_conf(premature)
    if premature then
        return
    end
    if exiting() then
        exit(0)
    end

    handle_dync_config()
    -- delay 5秒后，循环调用check_conf
    timer_at(delay, _M.check_conf)
end

-- 插件初始化，10s后开始执行check_conf
function _M:init_worker()
    ngx_log(ngx.INFO, "starting check lua module timer ...")
    timer_at(10, _M.check_conf)
end

return _M