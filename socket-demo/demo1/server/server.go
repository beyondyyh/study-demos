package main

import (
	"log"
	"net"
)

// 通过go的net包，实现一个 TCP 服务端
// 1. 端口监听。通过 `net.Listen("tcp", ":8000")` 开启在端口8000的TCP连接监听；
// 2. 建立连接。监听成功之后，调用 `net.Listener.Accept()` 方法等待TCP连接，Accept方法将以阻塞的方式等待新连接的到达，并将该连接作为 `net.Conn` 接口类型返回；
// 3. 数据传输。连接建立成功之后，启动一个新goroutine来处理 `c` 连接上的读取和写入。

func main() {
	// 1. create a listener
	l, err := net.Listen("tcp", ":8000")
	if err != nil {
		log.Fatalf("Error listener returned: %v", err)
	}
	defer l.Close()

	for {
		// 2. accept new connections
		c, err := l.Accept()
		if err != nil {
			log.Fatalf("Error to accept new connections: %v", err)
		}

		// 3. create a goroutine that reads and write back data
		go func() {
			log.Println("TCP session open")
			defer c.Close()

			for {
				d := make([]byte, 100)

				// Read from tcp buffer
				_, err := c.Read(d)
				if err != nil {
					log.Printf("Error reading TCP session: %v", err)
					break
				}
				log.Printf("reading data from client: %s\n", string(d))

				// Write back data to TCP client
				_, err = c.Write(d)
				if err != nil {
					log.Printf("Error writing TCP session: %v", err)
					break
				}
			}
		}()
	}
}
