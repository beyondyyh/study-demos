# openresty-demo

## 安装、服务启停

**源码安装：**
```sh
# 下载源码
wget -O ngx_openresty-1.9.7.1.tar.gz https://openresty.org/download/ngx_openresty-1.9.7.1.tar.gz

# 解压后编译
cd ~/Workspace/study/openresty/ngx_openresty-1.9.7.1/
# 安装路径：/usr/local/openresty/
./configure --prefix=/usr/local/openresty/\
            --with-cc-opt="-I/usr/local/include"\
            --with-luajit\
            --without-http_redis2_module \
            --with-ld-opt="-L/usr/local/lib"
```

> ngx_openresty安装路径：/usr/local/openresty
> nginx可执行文件路径：/usr/local/openresty/nginx/sbin，已经加入PATH

**start：**
```sh
nginx -p `pwd`/../openresty-demo
```

**查看进程：**
```sh
$ ps -ef|grep openresty-demo
  501 23459     1   0  6:01PM ??         0:00.00 nginx: master process nginx -p /Users/yehong/Workspace/study/go/src/beyondyyh/study-demos/openresty-demo/../openresty-demo
  501 24323 31012   0  6:02PM ttys003    0:00.00 grep openresty-demo
```

**stop：**
```sh
nginx -p `pwd`/../openresty-demo -s stop
```

## 配置文件

- **location匹配规则** [location.conf](conf/servers/location.conf) 

| 模式 | 含义 |
| --- | --- |
| location = /uri | `=`表示精确匹配，只有无安全匹配上才能生效 |
| location ^~ /uri | `^~`开头对URL路径进行前缀匹配，并且在正则之前 |
| location ~ pattern | 表示`区分大小写`的正则匹配  |
| location ~* pattern | 表示`不区分大小写`的正则匹配 |
| location /uri | 不带任何修饰符，也表示前缀匹配，但是在正则匹配之后 |
| location / | 通用匹配，任何未匹配到其它location的请求都会匹配到，相当于switch中的default |

> **多个 location 配置的情况下匹配顺序为：**
>- 首先精确匹配 `=`
>- 其次前缀匹配 `^~`
>- 其次是按文件中顺序的`正则匹配`
>- 然后匹配不带任何修饰的前缀匹配
>- 最后是交给 `/` 通用匹配
>- 当有匹配成功时候，停止匹配，按当前匹配规则处理请求。

- **获取uri参数** [print_url.conf](conf/servers/print_args.conf)

- **获取请求body、输出响应体** [print_body.conf](conf/servers/print_body.conf)
  - nginx.say和ngx.print均为异步输出；
  - nginx.say会对响应体多输出一个`\n`，如果是浏览器输出而且没有区别，但是终端调试工具下使用ngx.say会比较方便。

- **日志标准输出**