require "resty.core.regex"


-- 纯 lua 版本，优点是兼容性好，可以适用任何 lua 语言环境
function check_hex_lua(str)
    if "string" ~= type(str) then
        return false
    end

    for i = 1, #str do
        local ord = str:byte(i)
        if not (
            (48 <= ord and ord <= 57) or
                (65 <= ord and ord <= 70) or
                (97 <= ord and ord <= 102)
            ) then
            return false
        end
    end
    return true
end

-- 使用 ngx.re.* 完成，没有使用任何调优参数
function check_hex_default(str)
    if "string" ~= type(str) then
        return false
    end

    return ngx.re.find(str, "[^0-9a-fA-F]") == nil
end

-- 使用 ngx.re.* 完成，使用调优参数 "jo"
function check_hex_jo(str)
    if "string" ~= type(str) then
        return false
    end

    return ngx.re.find(str, "[^0-9a-fA-F]", "jo") == nil
end

-- 下面就是测试用例部分代码
function do_test(name, fun)
    ngx.update_time()
    local start = ngx.now()

    local t = "012345678901234567890123456789abcdefABCDEF"
    assert(fun(t))
    for i = 1, 10000 * 300 do
        fun(t)
    end

    ngx.update_time()
    print(name, "\ttimes:", ngx.now() - start)
end

do_test("check_hex_lua", check_hex_lua)
do_test("check_hex_default", check_hex_default)
do_test("check_hex_jo", check_hex_jo)

-- 测试：
-- resty test.lua
-- output:
-- check_hex_lua   times:0.30799984931946
-- check_hex_default       times:2.2239999771118
-- check_hex_jo    times:0.24900007247925
