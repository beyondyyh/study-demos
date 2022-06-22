local ngx_re_gmatch = ngx.re.gmatch
local table_insert = table.insert

local _M = { _VERSION = '0.01' }

_M.split = function(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

function _M.spliturl(path)
    if path and type(path) == "string" and path ~= "" then
        local t = {}
        for w in ngx_re_gmatch(path, "([^'?']+)") do
            table_insert(t, w[1])
        end
        return t[1], t[2] or ""
    else
        return path, ""
    end
end

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
            local tab = string.rep("  ", tabcount) -- 2个空格代替tab
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

function _M.format(v)
    if not v then
        return "nil"
    end

    if type(v) == 'string' then
        return format_value(v)
    end

    if type(v) == "table" then
        return format_table(v, 1)
    end

    return v
end

return _M
