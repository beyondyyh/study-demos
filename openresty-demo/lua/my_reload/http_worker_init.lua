local ngx_log = ngx.log
local INFO = ngx.INFO

ngx_log(INFO, 'init plugins ......')
local phases = require "my_reload.plugin.phases"
ngx.timer.at(1, phases.init_phases)