local _M = { _VERSION = "0.0.1"}

local function format_value(val)
    if type(val) == "string" then
        return string.format("%q", val)
    end

    return tostring(val)
end

--[[
format_table格式化输出table
tabcount表示缩进的tab数
]]
function _M.format_table(t, tabcount)
    tabcount = tabcount or 0
    if tabcount > 5 then
        --防止栈溢出
        return "<table too deep>" .. tostring(t)
    end
    local str = ""
    if type(t) == "table" then
        str = "{\n"
        for k, v in pairs(t) do
            local tab = string.rep("\t", tabcount)
            if type(v) == "table" then
                str = str .. tab .. string.format("[%s] = {", format_value(k)) .. '\n'
                str = str .. _M.format_table(v, tabcount + 1) .. tab .. '}\n'
            else
                str = str .. tab .. string.format("[%s] = %s", format_value(k), format_value(v)) .. ',\n'
            end
        end
        str = str .. "\n}"
    else
        str = str .. tostring(t) .. '\n'
    end

    return str
end

--[[
format格式化输出数据
]]
function _M.format(v)
    if not v then
        return "nil"
    end

    if type(v) == 'string' then
        return format_value(v)
    end

    if type(v) == "table" then
        return _M.format_table(v, 1) -- 缩进1个tab
    end

    return v
end

return _M