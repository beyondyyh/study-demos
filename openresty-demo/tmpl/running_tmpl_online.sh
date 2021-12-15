#!/usr/bin/env bash

base=`pwd`/..
lf=${base}/lua/dync/config.lua

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

# 避免supervisor在停止consul-template之后，再次启动之后，可能会存在多个进程的BUG
ps -ef|grep "consul-template" | grep "${base}/tmpl/config.ctmpl" | grep -v grep | awk '{print $2}' | xargs kill -9

# 阻塞式监听
${ct} \
  -consul-addr ${host}:${port} \
  -template "${base}/tmpl/config.ctmpl:${lf}:/bin/bash -c '${base}/tmpl/running_notice_online.sh ${lf} || true'" \
  -retry 30s