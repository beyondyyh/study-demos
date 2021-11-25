--========== {$prefix}/lua/simple-api/subtraction.lua
local args = ngx.req.get_uri_args()
ngx.say(args.a - args.b)