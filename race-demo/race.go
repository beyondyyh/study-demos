package race_demo

import (
	"fmt"
	"math/rand"
	"runtime"
	"time"
)

// 在使用定时器, 0到1秒的随机时间间隔之后打印消息。 打印过程反复进行了五秒钟。
// 使用 time.AfterFunc 为第一条消息创建一个 Timer ，然后使用 Reset 方法调度下一条消息，
// 每次都复用原有 Timer 。
//
// 这似乎是合理的代码，但在某些情况下，它以令人惊讶的方式失败：
// panic: runtime error: invalid memory address or nil pointer dereference
// [signal 0xb code=0x1 addr=0x8 pc=0x41e38a]
//
// 使用 go test -race -run Test_race1进行测试，发现有数据出现 `race condition`：
// 竞态探测器展示出问题根源：来自不同 goroutines 对变量 t 有不同步读和写。
// 如果初始定时器时间间隔非常小，则定时器函数可能会在主 goroutine 赋值到 t 之前触发，因此对 t.Reset 的调用发生在 nil 上。
func race1() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	start := time.Now()
	var t *time.Timer
	t = time.AfterFunc(randomDuration(), func() {
		fmt.Println(time.Now().Sub(start))
		t.Reset(randomDuration())
	})
	time.Sleep(5 * time.Second)
}

// 修复这个 race condition 问题，可通过读写发生在一个 goroutine 中：
func race2() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	start := time.Now()
	reset := make(chan bool)
	var t *time.Timer
	t = time.AfterFunc(randomDuration(), func() {
		fmt.Println(time.Now().Sub(start))
		reset <- true
	})
	for time.Since(start) < 5*time.Second {
		<-reset
		t.Reset(randomDuration())
	}
}

func randomDuration() time.Duration {
	return time.Duration(rand.Int63n(1e9))
}
