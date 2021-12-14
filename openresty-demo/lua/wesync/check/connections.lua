local cjson = require "cjson"
local ngx_say = ngx.say

local function split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end

    return result
end

-- 加载自动生成的当前系统打包版本
local _, version = pcall(require, "kversion")

-- 输出当前业务版本
local vers
if version then
    vers = version.version
else
    vers = "0.0.0"
end

local c = {}
c.current = tonumber(ngx.var.connections_active) --包括读、写和空闲连接数

c.active = ngx.var.connections_reading + ngx.var.connections_writing

c.idle = tonumber(ngx.var.connections_waiting)
c.writing = tonumber(ngx.var.connections_writing)
c.reading = tonumber(ngx.var.connections_reading)

local t = {
    connections = c,
    version = vers,
    -- 记录本次系统时间戳，方便检测读取后校对时间差值，一般时间超过30秒，该状态信息可认为无效
    time = ngx.time()
}

local tmp = io.popen('/usr/sbin/ss -tan | /usr/bin/awk \'NR>1{++S[$1]}END{for (a in S) print a,S[a]}\'')
local data = split(tmp:read("*all"), '\n')
local data_table = {}
if data then
    for _, stat in ipairs(data) do
        local idx, _ = string.find(stat, ' ')
        if idx and idx > 0 then
            local key = string.sub(stat, 1, idx-1)
            local val = tonumber(string.sub(stat, idx+1))
            if key and val then
                data_table[key] = val
            end
        end
    end
end

t.netstat = data_table

ngx.header["Content-Type"] = "application/json; charset=utf-8"
ngx_say(cjson.encode(t))