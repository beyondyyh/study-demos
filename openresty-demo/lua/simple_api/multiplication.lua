--========== {$prefix}/lua/simple-api/multiplication.lua
local args = ngx.req.get_uri_args()
ngx.say(args.a * args.b)