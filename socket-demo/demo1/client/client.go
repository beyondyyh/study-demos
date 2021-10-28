package main

import (
	"log"
	"net"
	"time"
)

// 通过go的net包，实现一个 TCP 客户端
// 1. 建立连接。通过 `net.Dial("tcp", "localhost:8000")` 连接一个 TCP 连接到服务器正在监听的同一个 localhost:8000 地址。
// 2. 写入数据。当连接建立成功后，通过 c.Write() 方法写入数据 Hi, beyondyyh 给服务器。
// 3. 关闭连接。启动一个新的 goroutine，在 10s 后调用 c.Close() 方法关闭 TCP 连接。
// 4. 读取数据。除非发生 error，否则客户端通过 c.Read()  方法（注意：是阻塞式的）循环读取 TCP 连接上的内容。

func main() {
	// 1. open a TCP session to server
	c, err := net.Dial("tcp", "localhost:8000")
	if err != nil {
		log.Fatalf("Error to open TCP connection: %v", err)
	}
	defer c.Close()

	// 2. write some data to server
	log.Println("TCP session open")
	b := []byte("Hi, beyondyyh")
	_, err = c.Write(b)
	if err != nil {
		log.Fatalf("Error writing TCP session: %v", err)
	}

	// 3. create a goroutine that closes TCP session after 10 seconds
	go func() {
		<-time.After(time.Duration(10) * time.Second)
		defer c.Close()
	}()

	// 4. read any responses until get an error
	for {
		d := make([]byte, 100)
		_, err = c.Read(d)
		if err != nil {
			log.Fatalf("Error reading TCP session: %s", err)
		}
		log.Printf("reading data from server: %s\n", string(d))
	}
}
