local ngx_re_gmatch = ngx.re.gmatch
local table_insert = table.insert

local _M = {_VERSION = '0.01' }

_M.split = function (szFullString, szSeparator)
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

return _M