local ngx_update_time = ngx.update_time
local ngx_now = ngx.now

local _M = {}

function _M.delay_send(ctx, code, header)
    ctx.delayed_response = true
    ctx.delay_content = { code, header }
end

function _M.get_time()
    ngx_update_time()
    return ngx_now()
end

return _M