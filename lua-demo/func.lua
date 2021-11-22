local function run(x, y)
    print('run', x, y)
end

local function attack(target_id)
    print('target_id', target_id)
end

local function do_action(method, ...)
    local args = {...} or {}
    method(unpack(args, 1, table.maxn(arg)))
end

do_action(run, 1, 2)
do_action(attack, 1111)