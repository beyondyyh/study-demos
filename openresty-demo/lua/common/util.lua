local json = require "cjson"

local function is_array(table)
    local max = 0
    local count = 0
    for k, v in pairs(table) do
        if type(k) == "number" then
            if k > max then max = k end
            count = count + 1
        else
            return -1
        end
    end
    if max > count * 2 then
        return -1
    end

    return max
end

local serialise_value

local function serialise_table(value, indent, depth)
    local spacing, spacing2, indent2
    if indent then
        spacing = "\n" .. indent
        spacing2 = spacing .. "  "
        indent2 = indent .. "  "
    else
        spacing, spacing2, indent2 = " ", " ", false
    end
    depth = depth + 1
    if depth > 50 then
        return "Cannot serialise any further: too many nested tables"
    end

    local max = is_array(value)

    local comma = false
    local fragment = { "{" .. spacing2 }
    if max > 0 then
        -- Serialise array
        for i = 1, max do
            if comma then
                table.insert(fragment, "," .. spacing2)
            end
            table.insert(fragment, serialise_value(value[i], indent2, depth))
            comma = true
        end
    elseif max < 0 then
        -- Serialise table
        for k, v in pairs(value) do
            if comma then
                table.insert(fragment, "," .. spacing2)
            end
            table.insert(fragment,
                ("[%s] = %s"):format(serialise_value(k, indent2, depth),
                    serialise_value(v, indent2, depth)))
            comma = true
        end
    end
    table.insert(fragment, spacing .. "}")

    return table.concat(fragment)
end

-- 序列化对象
---@param value any
---@param indent string 缩进字符串 如2个空格"  "
---@param depth integer 缩进深度
---@return string
function serialise_value(value, indent, depth)
    if indent == nil then indent = "" end
    if depth == nil then depth = 0 end

    if value == json.null then
        return "json.null"
    elseif type(value) == "string" then
        return ("%q"):format(value)
    elseif type(value) == "nil" or type(value) == "number" or
        type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "table" then
        return serialise_table(value, indent, depth)
    else
        return "\"<" .. type(value) .. ">\""
    end
end

local function file_load(filename)
    local file
    if filename == nil then
        file = io.stdin
    else
        local err
        file, err = io.open(filename, "rb")
        if file == nil then
            error(("Unable to read '%s': %s"):format(filename, err))
        end
    end
    local data = file:read("*a")

    if filename ~= nil then
        file:close()
    end

    if data == nil then
        error("Failed to read " .. filename)
    end

    return data
end

local function file_save(filename, data)
    local file
    if filename == nil then
        file = io.stdout
    else
        local err
        file, err = io.open(filename, "wb")
        if file == nil then
            error(("Unable to write '%s': %s"):format(filename, err))
        end
    end
    file:write(data)
    if filename ~= nil then
        file:close()
    end
end

local function compare_values(val1, val2)
    local type1 = type(val1)
    local type2 = type(val2)
    if type1 ~= type2 then
        return false
    end

    -- Check for NaN
    if type1 == "number" and val1 ~= val1 and val2 ~= val2 then
        return true
    end

    if type1 ~= "table" then
        return val1 == val2
    end

    -- check_keys stores all the keys that must be checked in val2
    local check_keys = {}
    for k, _ in pairs(val1) do
        check_keys[k] = true
    end

    for k, v in pairs(val2) do
        if not check_keys[k] then
            return false
        end

        if not compare_values(val1[k], val2[k]) then
            return false
        end

        check_keys[k] = nil
    end
    for k, _ in pairs(check_keys) do
        -- Not the same if any keys from val1 were not found in val2
        return false
    end
    return true
end

-- Export functions
return {
    serialise_value = serialise_value,
    file_load = file_load,
    file_save = file_save,
    compare_values = compare_values,
}
