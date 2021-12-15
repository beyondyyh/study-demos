#!/usr/bin/env bash

function get_time(){
    date '+%Y-%m-%d %H:%M:%S'
}

base=`pwd`/..
exec >> ${base}/logs/consul_watch.log
lf=${base}/lua/dync/config.lua

echo "`get_time` update_dync_config.sh now ..."

ct=${base}/tmpl/consul-template

os=`uname -s`
if [ $os == "Darwin" ]; then
    ct=${base}/tmpl/consul-template_darwin
fi

host="127.0.0.1"
port=8500

cnum=`ps -ef|grep "consul agent" | grep client | grep -v grep | wc -l`

if [ $cnum -eq 0 ]; then
    host="这里填写您的Consul服务器地址"
fi

echo "`get_time` now run consul-template command"

# 只监听一次，用作debug
${ct} \
  -consul-addr ${host}:${port} \
  -template "${base}/tmpl/config.ctmpl:${lf}:/bin/bash -c '${base}/tmpl/running_notice_online.sh ${lf} || true'" \
  -retry 30s \
  -wait=5s:10s \
  -log-level=info \
  -max-stale=0s \
  -once 2>&1

echo "`get_time` Done !"