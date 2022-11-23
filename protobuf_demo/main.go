package main

import (
	"bytes"
	"fmt"
	"io"

	pb "protobuf_demo/protos"
)

func writePerson(w io.Writer, p *pb.Person) {
	fmt.Fprintln(w, "  Person ID:", p.Id)
	fmt.Fprintln(w, "  Name:", p.Name)
	if p.Email != "" {
		fmt.Fprintln(w, "  E-mail address:", p.Email)
	}

	for _, pn := range p.Phones {
		switch pn.Type {
		case pb.Person_MOBILE:
			fmt.Fprint(w, "  Mobile phone #: ")
		case pb.Person_HOME:
			fmt.Fprint(w, "  Home phone #: ")
		case pb.Person_WORK:
			fmt.Fprint(w, "  Work phone #: ")
		}
		fmt.Fprintln(w, pn.Number)
	}
}

func main() {
	buf := new(bytes.Buffer)
	// [START populate_proto]
	p := pb.Person{
		Id:    1234,
		Name:  "John Doe",
		Email: "jdoe@example.com",
		Phones: []*pb.Person_PhoneNumber{
			{Number: "555-4321", Type: pb.Person_HOME},
		},
	}
	// [END populate_proto]
	writePerson(buf, &p)
	fmt.Println(buf.String())
}
