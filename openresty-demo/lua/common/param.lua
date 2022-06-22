local _M = { _VERSION = "0.0.1" }

-- 对输入参数进行校验，只要不为数字则返回false
function _M.is_number(...)
    -- ...表示可变参数
    local arg = { ... }
    local num
    for _, v in ipairs(arg) do
        num = tonumber(v)
        if nil == num then
            return false
        end
    end
    return true
end

return _M
