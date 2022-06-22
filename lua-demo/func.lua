local function run(x, y)
    print('run', x, y)
end

local function attack(target_id)
    print('target_id', target_id)
end

local function do_action(method, ...)
    local args = { ... } or {}
    method(unpack(args, 1, table.maxn(arg)))
end

local function gen_uuid()
    local uuid = require 'uuid'
    print("====", uuid.generate())
end

do_action(run, 1, 2)
do_action(attack, 1111)

for i = 1, 10, 1 do
    gen_uuid()
end

-- 测试：
-- resty func.lua
