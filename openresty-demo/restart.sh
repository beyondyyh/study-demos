#/bin/sh

## openresty安装路径：/usr/local/openresty

openresty -p `pwd`/../openresty-demo -s stop
openresty -p `pwd`/../openresty-demo
