package ccutils

import (
	"encoding/json"
)

type ErrorWithStack struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (e ErrorWithStack) Error() string {
	bytes, err := json.Marshal(e)
	if err != nil {
		panic(err)
	}

	return string(bytes)
}

func CreateError(code int, err error) error {
	return &ErrorWithStack{
		Code:    code,
		Message: err.Error(),
	}
}
