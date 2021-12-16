---
--- 设置请求唯一id
---

-- 生成19位唯一logid
local function genLogID()
    ngx.update_time()
    -- ngx.now()返回一个保护3位浮点数的毫秒数
    -- reverse():sub(1, 9)反转字符串取钱9位防止 转换为number溢出
    math.randomseed(tonumber(tostring(ngx.now()*1000):reverse():sub(1, 9)))
    local logid = string.format("%.0f", math.random(1000000000000000000, 9223372036854775807))
    return logid
end

-- 请求来源的header中没取到，则生成一个
local logid = ngx.req.get_headers()['X-Mp-Logid']
-- ngx.log(ngx.INFO, "ngx.time: " .. ngx.now() .. "\treq.headers: " .. require("common.tool").format(ngx.req.get_headers()))
if not logid or logid == "" then
    logid = genLogID()
end

-- assign to nginx var
ngx.var.x_mp_logid = logid

-- set to request header
ngx.req.set_header('X-Mp-Logid', logid)
