--
-- 用于查看wesync/config以及dync/config等配置文件某个键值是否生效
--

local ngx_say = ngx.say
local arg = ngx.req.get_uri_args()
local key = arg.key
local format = require("wesync.tool").format

local wesync_config = require 'wesync.config'
local dync_config = require 'dync.config'
local compare = require 'wesync.compare'

if key == "dump" then
    ngx_say("dync.config table: \n" .. format(dync_config))
    ngx_say("wesync.config table: \n" .. format(wesync_config))
else
    local wkey = "wesync.config." .. key
    local wval = wesync_config[key]
    local dkey = "dync.config." .. key
    local dval = dync_config[key]

    ngx_say("key: " .. key .. "\n" .. wkey .. " = " .. format(wval) .. "\n" .. dkey .. " = " .. format(dval))

    local result = compare.is_equal(wkey, dval)
    if result == true then
        ngx_say(wkey .. " = " .. dkey)
    else
        ngx_say(wkey .. " ≠ " .. dkey)
    end
    ngx_say("result: " .. wkey .. " " ..  format(wval) .. " " .. tostring(result))
end
