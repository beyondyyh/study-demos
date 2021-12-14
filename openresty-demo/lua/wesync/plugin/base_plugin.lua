local _M = {}
_M.__index = _M

local ngx_log = ngx.log
local DEBUG = ngx.DEBUG

_M.name = "base_plugin"
_M.priority = 10

-- 是否需要在发生错误时跳过该插件，默认为false，即可跳过
-- 只有关键插件发生错误，导致后续业务请求无法继续下去时，才需要在相应插件处覆盖该值设置为true
_M.break_on_error = false

function _M:new()
    return self
end

function _M:extend()
    local cls = {}
    for k, v in pairs(self) do
        if k:find("__") == 1 then
            cls[k] = v
        end
    end
    cls.__index = cls
    cls.super = self
    setmetatable(cls, self)
    return cls
end

function _M:__tostring()
    return self.name
end

function _M:init_worker()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": init_worker")
end

function _M:access()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": access")
end

function _M:log()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": log")
end

function _M:uninstall()
    ngx_log(ngx.ERR, "uninstall plugin \"", self._name, "\": log")
end

return _M