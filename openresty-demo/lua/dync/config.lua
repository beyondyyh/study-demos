---
--- 该文件通过某种机制自动生成，请勿修改
--- 例如：consul kv作为存储，consul-watch + consul-template 自动生成文件
---

local _M = { _VERSION = '0.05' }

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
    ["photo/info"] = true,
    ["push/active"] = 2222222222
}

return _M