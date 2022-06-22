function check_args_template(args, template)
  if type(args) ~= type(template) then
    return false
  elseif "table" ~= type(args) then
    return true
  end

  for k, v in pairs(template) do
    if type(v) ~= type(args[k]) then
      return false
    elseif "table" == type(v) then
      if not check_args_template(args[k], v) then
        return false
      end
    end
  end

  return true
end

local args = { name = "myname", tel = 888888, age = 18,
  mobile_no = 13888888888, love_things = { "football", "music" } }

print("valid   check: ", check_args_template(args, { name = "", tel = 0, love_things = {} }))
print("unvalid check: ", check_args_template(args, { name = "", tel = 0, love_things = {}, email = "" }))


-- 测试：
-- resty check_args_template.lua
-- output:
-- valid   check: true
-- unvalid check: false
