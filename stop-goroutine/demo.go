package stop_goroutine

import (
	"context"
	"fmt"
	"time"
)

func demo1() {
	ch := make(chan int, 10)
	go func() {
		for {
			v, ok := <-ch
			if !ok {
				fmt.Println("channel colsed")
				return
			}
			fmt.Println(v)
		}
	}()
	ch <- 1
	ch <- 2
	ch <- 3
	close(ch)
	time.Sleep(1 * time.Second)
}

func demo2() {
	ch := make(chan int, 10)
	done := make(chan struct{})
	go func() {
		// 轮询监听done信号，监听到之后退出goroutinue
		for i := 0; ; i++ {
			select {
			case ch <- i:
			case <-done:
				close(ch)
				return
			}
			// 模拟业务逻辑代码执行的时间200ms，理论上1s钟会输出5个数
			time.Sleep(200 * time.Millisecond)
		}
	}()

	// 2s后向done发送一个信号
	go func() {
		time.Sleep(2 * time.Second)
		done <- struct{}{}
	}()

	for i := range ch {
		fmt.Printf("receive i: %d\n", i)
	}
	fmt.Println("end!")
}

func demo3() {
	ch := make(chan struct{})
	ctx, cancel := context.WithCancel(context.Background())
	go func(ctx context.Context) {
		for {
			select {
			case <-ctx.Done():
				fmt.Printf("err: %s\n", ctx.Err().Error())
				ch <- struct{}{}
				return
			default:
				fmt.Println("时候未到...")
			}
			// 模拟业务执行时间500ms
			time.Sleep(5 * time.Millisecond)
		}
	}(ctx)

	go func() {
		time.Sleep(3 * time.Second)
		cancel()
	}()

	<-ch // block
	fmt.Println("end!")
}
