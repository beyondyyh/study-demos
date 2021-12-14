---
--- http协议入口
---

local ngx_say = ngx.say
local dync_config = require "wesync.helper.dync_config"
local dict = ngx.shared.http_dync_confs

ngx.req.read_body()
local arg = ngx.req.get_post_args()
local ori = arg.data

local result, err = dync_config.handle_directive(dict, ori)

ngx_say("receive: " .. ori .. ", handle result: " .. tostring(result) .. ", with error: " .. tostring(err))