#!/usr/bin/env bash

## 查找新增或添加的文件中以.lua为后缀的文件，执行luacheck静态文件语法检查
lua_files=$(git status -s|awk '{if (($1=="M"||$1=="A") && $2 ~ /.lua$/)print $2;}')

if [[ "$lua_files" != "" ]]; then
    result=$(luacheck $lua_files)

    if [[ "$result" =~ .*:.*:.*: ]]; then
        echo "$result"
        echo ""
        exec < /dev/tty
        read -p "Abort commit?(Y/n)"

        if [[ "$REPLY" == y* ]] || [[ "$REPLY" == Y* ]]; then
            echo "Abort commit"
            exit 1
        fi
    fi
fi
