package ccutils

import (
	"encoding/json"
)

// Stack 및 logger는 debug용

type ErrorWithStack struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	//Stack   string `json:"stack"`
}

func (e ErrorWithStack) Error() string {
	bytes, err := json.Marshal(e)
	if err != nil {
		panic(err)
	}

	return string(bytes)
}

func CreateError(code int, err error) error {
	//logger.Info(err.Error())
	//logger.Info(string(debug.Stack()))
	return &ErrorWithStack{
		Code:    code,
		Message: err.Error(),
		//Stack:   string(debug.Stack()),
	}
}
