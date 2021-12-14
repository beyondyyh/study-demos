---
--- http worker初始化
---

local ngx_log = ngx.log
local INFO = ngx.INFO

ngx_log(INFO, 'init plugins ......')
local phases = require "wesync.plugin.phases"

-- ngx.timer.at
-- syntax: hdl, err = ngx.timer.at(delay, callback, user_arg1, user_arg2, ...)
-- 创建一个timer，1秒后执行插件初始化操作
ngx.timer.at(1, phases.init_phases)