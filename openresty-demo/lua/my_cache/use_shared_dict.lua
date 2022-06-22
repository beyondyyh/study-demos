-- file use_shared_dict.lua: example "use_shared_dict" module
-- require "resty.core"

local _M = { _VERSION = '0.01' }

local ngx_cache = ngx.shared.my_cache

local function set(key, value, exptime)
    if not exptime then
        exptime = 0
    end

    -- 在nginx.conf中定义的，`lua_shared_dict my_cache 32m;`
    local succ, err, forcible = ngx_cache:set(key, value, exptime)
    if not succ then
        ngx.log(ngx.ERR, "ngx.shared.dict set with key: " .. _M.key .. ", value: " .. value .. " got error: " .. err)
        return false
    end
    if forcible then
        ngx.log(ngx.INFO, "ngx.shared.dict overflow")
    end
    return succ
end

local function get(key)
    return ngx_cache:get(key)
end

function _M.go()
    set("dog", 32)
    set("cat", 56)
    set("pushapplet", '值为"feature_wbox_value1_value2"，其中value1为客户端上行appid；value2为appid对应的小程序最新版本号')
    ngx.say("dog: ", get("dog"))
    ngx.say("cat: ", get("cat"))
    ngx.say("pushapplet: ", get("pushapplet"))
end

return _M
