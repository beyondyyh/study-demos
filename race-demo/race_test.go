package race_demo

import "testing"

// run: go test -race -v -run Test_race1
func Test_race1(t *testing.T) {
	race1()
}

// run: go test -race -v -run Test_race2
func Test_race2(t *testing.T) {
	race2()
}
