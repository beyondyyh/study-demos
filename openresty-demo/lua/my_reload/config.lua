-- 外部SQL/NOSQL等连接信息
-- User: nieyong
-- Date: 2017/4/10
-- Time: 下午7:27

local _M = { _VERSION = '0.01' }


local __proxy = {}
local __mt = {
    __index = function(self, key)
        local dconf = package.loaded['dync.config']
        if not dconf then
            return _M[key]
        end

        return dconf[key] or _M[key]
    end
}

return setmetatable(__proxy, __mt)
