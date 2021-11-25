local resolver = require "resty.dns.resolver"

-- deps：luarocks-5.3 install lua-resty-dns --local
-- deps：luarocks-5.3 install lua-resty-http --local

local r, err = resolver:new{
    nameservers = {"8.8.8.8", {"8.8.4.4", 53} },
    retrans = 5,  -- 5 失败重试次数
    timeout = 2000,  -- 2 sec
}

if not r then
    ngx.say("failed to instantiate the resolver: ", err)
    return
end

local answers, err = r:query("www.google.com")
if not answers then
    ngx.say("failed to query the DNS server: ", err)
    return
end

if answers.errcode then
    ngx.say("server returned error code: ", answers.errcode, ": ", answers.errstr)
end

for i, ans in ipairs(answers) do
    ngx.say(ans.name, " ", ans.address or ans.cname,
            " type:", ans.type, " class:", ans.class,
            " ttl:", ans.ttl)
end