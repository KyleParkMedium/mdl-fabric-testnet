package ccutils

import (
	"encoding/json"
)

func StringToMap(arg string) map[string]interface{} {
	var request map[string]interface{}
	err := json.Unmarshal([]byte(arg), &request)
	if err != nil {
		return nil
	}
	return request
}

func StructToMap(arg interface{}) (map[string]interface{}, error) {
	data, err := json.Marshal(arg) // Convert to a json string
	if err != nil {
		return nil, CreateError(ChaincodeError, err)
	}

	result := make(map[string]interface{})
	err = json.Unmarshal(data, &result) // Convert to a map
	return result, nil
}
