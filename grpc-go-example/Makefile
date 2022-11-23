# helloworld demo
gen-helloworld:
	protoc --proto_path=./protos \
	--go_out=./protos --go_opt=paths=source_relative \
	./protos/helloworld/helloworld.proto

# helloworld demo with gRPC
gen-helloworld-grpc:
	protoc --proto_path=./protos \
	--go_out=./protos --go_opt=paths=source_relative \
	--go-grpc_out=./protos --go-grpc_opt=paths=source_relative \
	./protos/helloworld/helloworld.proto

# grpc-gateway demo
gen-gw:
	protoc --proto_path=./protos \
   --go_out=./protos --go_opt=paths=source_relative \
   --go-grpc_out=./protos --go-grpc_opt=paths=source_relative \
   --grpc-gateway_out=./protos --grpc-gateway_opt=paths=source_relative \
   ./protos/gateway/gateway.proto

# # proto import demo
# gen-imp:
# 	protoc --proto_path=. --go_out=. ./protos/import/*.proto

# go install \
#     github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest \
#     github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest \
#     google.golang.org/protobuf/cmd/protoc-gen-go@latest \
#     google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
