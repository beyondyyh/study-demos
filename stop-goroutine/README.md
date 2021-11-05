# 停止Goroutine的几种方式

## 关闭channel

借助于channel的close机制，通过轮询来完成对goroutine的精准控制。

```golang
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
```

也可以利用 `for range` 的特性：

```golang
go func() {
    for v := range ch {
        fmt.Println(v)
    }
}()
```

> 一直循环遍历 ch，直到其关闭位置。

## 利用 `for-loop` 结合 `select` 关键字进行监听，定期轮询channel

```golang
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
```

**以上代码会输出：**

```bash
$ go test -v -run Test_demo2
=== RUN   Test_demo2
receive i: 0
receive i: 1
receive i: 2
receive i: 3
receive i: 4
receive i: 5
receive i: 6
receive i: 7
receive i: 8
receive i: 9
end!
--- PASS: Test_demo2 (2.03s)
PASS
ok      stop_goroutine  2.033s
```

- 声明了变量 done，其类型为 channel，用于作为信号量处理 goroutine 的关闭；
- 而 goroutine 的关闭是不知道什么时候发生的，因此在 Go 语言中会利用 `for-loop` 结合 `select` 关键字进行监听，再进行完毕相关的业务处理后，再调用 `close` 方法正式关闭 channel；
- 也可以不调用 close 方法，因为 goroutine 会自然结束，也就不需要手动关闭了。

## 使用context，超时控制或手动取消

```golang
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
```

**以上代码会输出：**

```bash
$ go test -v -run Test_demo3
=== RUN   Test_demo3
时候未到...
时候未到...
时候未到...
时候未到...
时候未到...
时候未到...
.........
err: context canceled
end!
--- PASS: Test_demo3 (3.01s)
PASS
ok      stop_goroutine  3.015s
```

- 在 context 中，我们可以借助 `ctx.Done` 获取一个只读的 `channel`，类型为结构体。可用于识别当前 channel 是否已经被关闭，其原因可能是到期，也可能是被取消了。
- context 对于跨 goroutine 控制有自己的灵活之处，可以调用 `context.WithTimeout` 来根据时间控制，也可以自己主动地调用 `cancel` 方法来手动关闭。

## 总结

- Go 语言中停止 goroutine 的三大经典方法（关闭channel、轮询channel，context）；
- 不可以跨goroutine强制关闭，因为在 Go 语言中，goroutine 只能自己主动退出，一般通过 `channel` 来控制，不能被外界的其他 goroutine 关闭或干掉，也没有 goroutine 句柄的显式概念。
- goroutine+panic+recover 也不能跨goroutinue捕获panic。
