package mock

import (
	"encoding/json"
	"reflect"
	"testing"

	"github.com/agiledragon/gomonkey"
	"github.com/stretchr/testify/assert"
)

func TestExec(t *testing.T) {
	var test = []struct {
		in   []byte
		want *Response
	}{
		{
			in:   []byte("https://gocn.vip/api/v1/count"),
			want: &Response{Result: "666"},
		},
	}
	var r Request
	f := func(t *testing.T) *gomonkey.Patches {
		patches := gomonkey.NewPatches()
		// mock json.Unmarshal()
		patches.ApplyFunc(json.Unmarshal, func(b []byte, d interface{}) error {
			data := d.(*Request)
			// 替换成任何你想要的数据
			(*data).Url = "127.0.0.1/api/v1/count"
			return nil
		})
		// mock 成员方法，注意，成员方法首字母要大写！
		patches.ApplyMethod(reflect.TypeOf(&r), "DoAction", func(_ *Request, _ string) (*Response, error) {
			return &Response{Result: "666"}, nil
		})
		return patches
	}
	t.Run("test", func(t *testing.T) {
		patches := f(t)
		defer patches.Reset()
		for _, v := range test {
			r, err := exec(v.in)
			if !assert.NotNil(t, r) {
				t.Log(err)
				continue
			}
			assert.Equal(t, "666", r.Result)
		}
	})
}
