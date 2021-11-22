#/bin/sh

nginx -p `pwd`/../openresty-demo -s stop
nginx -p `pwd`/../openresty-demo
