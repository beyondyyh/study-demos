--========== {$prefix}/lua/simple-api/addition.lua
local args = ngx.req.get_uri_args()
ngx.say(args.a + args.b)