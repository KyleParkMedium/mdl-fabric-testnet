package ccutils

import (
	"encoding/json"
)

type Response struct {
	TxId    string      `json:"txId"`
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

func GenerateErrorResponse(err error) (*Response, error) {
	return nil, err
}

func GenerateSuccessResponse(txId string, code int, message string, data interface{}) (*Response, error) {
	response := &Response{
		TxId:    txId,
		Code:    code,
		Message: message,
		Data:    data,
	}

	//logger.Info("success :: ", response)

	return response, nil
}

func GenerateSuccessResponseByteArray(txId string, code int, msg string, dataBytes []byte) (*Response, error) {
	var data interface{}
	if err := json.Unmarshal(dataBytes, &data); err != nil {
		return GenerateErrorResponse(err)
	}

	return GenerateSuccessResponse(txId, code, msg, data)
}
