--
-- 用于查看wesync/config以及dync/config等配置文件某个键值是否生效
--

local ngx_say = ngx.say
local arg = ngx.req.get_uri_args()
local key = arg.key

local function format_value(val)
    if type(val) == "string" then
        return string.format("%q", val)
    end

    return tostring(val)
end

local function format_table(t, tabcount)
    tabcount = tabcount or 0
    if tabcount > 5 then
        --防止栈溢出
        return "<table too deep>" .. tostring(t)
    end
    local str = ""
    if type(t) == "table" then
        for k, v in pairs(t) do
            local tab = string.rep("\t", tabcount)
            if type(v) == "table" then
                str = str .. tab .. string.format("[%s] = {", format_value(k)) .. '\n'
                str = str .. format_table(v, tabcount + 1) .. tab .. '}\n'
            else
                str = str .. tab .. string.format("[%s] = %s", format_value(k), format_value(v)) .. ',\n'
            end
        end
    else
        str = str .. tostring(t) .. '\n'
    end

    return str
end

local function format(v)
    if not v then
        return "nil"
    end

    if type(v) == 'string' then
        return format_value(v)
    end

    if type(v) == "table" then
        return format_table(v)
    end

    return v
end

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
