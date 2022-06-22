local _M = { _VERSION = '0.01' }

local ngx = ngx

-- 主方法
function _M.test()
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(1000) -- 1s

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    -- -- 请注意这里 auth 的调用过程
    -- local count
    -- count, err = red:get_reused_times()
    -- if 0 == count then
    --     ok, err = red:auth("password")
    --     if not ok then
    --         ngx.say("failed to auth: ", err)
    --         return
    --     end
    -- elseif err then
    --     ngx.say("failed to get reused times: ", err)
    --     return
    -- end

    ok, err = red:set("dog", "an animal")
    if not ok then
        ngx.say("failed to set dog: ", err)
        return
    end

    ngx.say("set result: ", ok)

    -- 连接池大小是100个，并且设置最大的空闲时间是 10 秒
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
end

function _M.withoutpipeline()
    local start_time = ngx.now()
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(1000) -- 1s

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    local ok, err = red:set("name", "Beyondyyh")
    ngx.say("set result: ", ok)
    local res, err = red:get("name")
    ngx.say("name: ", res)

    local ok, err = red:set("sex", "Male")
    ngx.say("set result: ", ok)
    local res, err = red:get("sex")
    ngx.say("sex: ", res)

    ok, err = red:set("horse", "Bob")
    ngx.say("set result: ", ok)
    res, err = red:get("horse")
    ngx.say("horse: ", res)

    -- 放回连接池，连接池大小为100，每个连接最大空闲时间10s
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
    ngx.say("time used:", ngx.now() - start_time)
end

function _M.withpipeline()
    local start_time = ngx.now()
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(1000) -- 1 sec

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    red:init_pipeline()
    red:set("name", "Beyondyyh")
    red:set("sex", "Male")
    red:set("horse", "Bob")
    red:get("name")
    red:get("sex")
    red:get("horse")
    local results, err = red:commit_pipeline()
    if not results then
        ngx.say("failed to commit the pipelined requests: ", err)
        return
    end

    for i, res in ipairs(results) do
        ngx.say(i, ": ", tostring(res))
    end

    -- 放回连接池，连接池大小为100，每个连接最大空闲时间10s
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
    ngx.say("time used:", ngx.now() - start_time)
end

function _M.usescript()
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(1000) -- 1 sec

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    --- use scripts in eval cmd
    local id = 1
    local res, err = red:eval([[
                -- 注意：Redis执行脚本的时候，从 KEYS/ARGV 取出来的值类型为 string
                local info = redis.call('get', KEYS[1])
                info = cjson.decode(info)
                local g_id = info.gid
                local g_info = redis.call('get', g_id)
                return g_info
            ]], 1, id)
    if not res then
        ngx.say("failed to get the group info: ", err)
        return
    end

    ngx.say(res)

    -- 放回连接池，连接池大小为100，每个连接最大空闲时间10s
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
end

return _M
