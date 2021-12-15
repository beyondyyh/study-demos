#!/usr/bin/env bash
# 文件更新通知nginx reload lua

lf=$1
lv=`egrep "_VERSION" $lf | egrep -o "[[:digit:]]{1,}"`
lm=`echo $lf | egrep -o "code/.*" | sed 's/code\///g; s/\//./g; s/.lua//g'`
echo "lm: $lm, lv: $lv"

## http协议更新
curl -s -X POST -d "data=config ${lm} ${lv}" http://127.0.0.1:6666/dync/config

## tcp协议更新
echo "dync config ${lm} ${lv}" | nc 127.0.0.1 6666
