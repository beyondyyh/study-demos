local _M = { _VERSION = '0.01' }

_M.test_env = false

-- dync.config 加载失败的兜底方案
_M.myproxy_paths = {
    ["hot_search"] = false,
    ["search/getoneword"] = false,
    ["search_channel"] = false,
    ["search/word_associate"] = false,
    ["profile/friends"] = false,
    ["profile/followers"] = false,
    ["search"] = false,
    ["profile/cardlist"] = false,
    ["profile/collection"] = false,
    ["profile/like"] = false,
    ["photo/info"] = false,
    ["push/active"] = false
}

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

-- 自动加载机制
return setmetatable(__proxy, __mt)
