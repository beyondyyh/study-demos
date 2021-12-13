package mock

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
)

type Request struct {
	Url string
}

type Response struct {
	Result string
}

func exec(args []byte) (res *Response, err error) {
	var w Request
	if err = json.Unmarshal(args, &w); err != nil {
		return nil, err
	}
	if res, err = w.DoAction(w.Url); err != nil {
		return nil, err
	}
	return
}

func (r *Request) DoAction(action string) (resp *Response, err error) {
	var (
		res *http.Response
		b   []byte
	)
	if res, err = http.Get(action); err != nil {
		return nil, err
	}
	if b, err = ioutil.ReadAll(res.Body); err != nil {
		return nil, err
	}
	return &Response{Result: string(b)}, nil
}
