local _M = {}

function _M.is_equal(a, b)
    local function is_equal_table(t1, t2)
        if t1 == t2 then
            return true
        end

        for k,v in pairs(t1) do
            if type(t1[k]) ~= type(t2[k]) then
                return false
            end

            if type(t1[k]) == "table" then
                if not is_equal_table(t1[k], t2[k]) then
                    return false
                end
            else
                if t1[k] ~= t2[k] then
                    return false
                end
            end
        end

        for k,v in pairs(t2) do
            if type(t2[k]) ~= type(t1[k]) then
                return false
            end

            if type(t2[k]) == "table" then
                if not is_equal_table(t2[k], t1[k]) then
                    return false
                end
            else
                if t2[k] ~= t1[k] then
                    return false
                end
            end
        end

        return true
    end

    if type(a) ~= type(b) then
        return false
    end

    if type(a) == "table" then
        return is_equal_table(a,b)
    else
        return (a == b)
    end
end

return _M