package main

import (
	"context"
	"log"
	"os"
	"time"

	"google.golang.org/grpc"

	pb "github.com/beyondyyh/study-demos/grpc-go-example/protos/helloworld"
)

const (
	address     = "localhost:50051"
	defaultName = "beyondyyh"
)

func main() {
	conn, err := grpc.Dial(address, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("Dial err: %v", err)
	}
	defer conn.Close()

	c := pb.NewGreeterClient(conn)
	// 通过命令行参数指定 name
	name := defaultName
	if len(os.Args) > 1 {
		name = os.Args[1] //nolint
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	r, err := c.SayHello(ctx, &pb.HelloRequest{Name: name})
	if err != nil {
		log.Fatalf("Could not greet: %v", err)
	}
	log.Printf("Greeting: %s", r.GetMessage())
}
