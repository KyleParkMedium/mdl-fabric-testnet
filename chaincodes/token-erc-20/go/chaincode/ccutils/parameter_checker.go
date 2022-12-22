package ccutils

import (
	"fmt"
	"reflect"
	"time"

	"github.com/op/go-logging"
)

var logger = logging.MustGetLogger("ccutils")

func CheckRequireParameter(requireParameterFields []string, parameters map[string]interface{}) error {
	for _, requireParameter := range requireParameterFields {
		if _, exist := parameters[requireParameter]; !exist {
			return CreateError(ChaincodeError, fmt.Errorf("check require parameter : parameter key = %v, value = %v", requireParameter, parameters[requireParameter]))
		} else {
			if parameters[requireParameter] == nil {
				return CreateError(ChaincodeError, fmt.Errorf("check require parameter : parameter key = %v, value = %v", requireParameter, parameters[requireParameter]))
			}
		}

	}
	return nil
}

func CheckRequireTypeBool(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckRequireType(reflect.Bool, typeParameterFields, parameters)
}

func CheckRequireTypeString(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckRequireType(reflect.String, typeParameterFields, parameters)
}

func CheckRequireTypeFloat64(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckRequireType(reflect.Float64, typeParameterFields, parameters)
}

func CheckRequireTypeInt64(typeParameterFields []string, parameters map[string]interface{}) error {
	if err := CheckRequireType(reflect.Float64, typeParameterFields, parameters); err != nil {
		return err
	}

	for _, typeParameterField := range typeParameterFields {
		// 형변환을 통해 해당 파라메터가 int64인지 확인
		value, _ := parameters[typeParameterField].(float64)
		int64Value := int64(value)

		if value != float64(int64Value) {
			return CreateError(ChaincodeError, fmt.Errorf("check parameter type : parameter field = %v is not int64, value = %v, type = %v", typeParameterField, value, reflect.TypeOf(value)))
		}

	}
	return nil
}

func CheckRequireTypeArray(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckRequireType(reflect.Slice, typeParameterFields, parameters)
}

func CheckRequireTypeObject(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckRequireType(reflect.Map, typeParameterFields, parameters)
}

func CheckRequireType(requireType reflect.Kind, typeParameterFields []string, parameters map[string]interface{}) error {
	for _, typeParameterField := range typeParameterFields {
		// 해당 파라메터가 있는지 확인
		if _, exist := parameters[typeParameterField]; !exist {
			return CreateError(ChaincodeError, fmt.Errorf("check parameter type : parameter field = %v not found", typeParameterField))
		} else {
			// 해당 파라메터가 입력받은 타입인지 확인
			parameter := parameters[typeParameterField]
			if reflect.TypeOf(parameter).Kind() != requireType {
				return CreateError(ChaincodeError, fmt.Errorf("check parameter type : parameter field = %v is not %v, value = %v, type = %v", typeParameterField, requireType, parameter, reflect.TypeOf(parameter)))
			}
		}

	}
	return nil
}

func CheckRequireTypeDate(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckRequireType(reflect.String, typeParameterFields, parameters)
}

func CompareFieldType(source interface{}, data map[string]interface{}) error {
	switch reflect.TypeOf(source).Kind() {
	case reflect.Map:
		{
			convSource := source.(map[string]interface{})
			for key := range data {
				if _, exist := convSource[key]; exist {
					if reflect.TypeOf(convSource[key]).Kind() != reflect.TypeOf(data[key]).Kind() {
						return CreateError(ChaincodeError, fmt.Errorf("check parameter type : [%s] parameter require %v, type = %v\n", key, reflect.TypeOf(convSource[key]), reflect.TypeOf(data[key])))
					}
				}
			}
		}
	case reflect.Struct:
		{
			convSource, err := StructToMap(source)
			if err != nil {
				return CreateError(ChaincodeError, err)
			}

			for key := range data {
				if _, exist := convSource[key]; exist {
					if reflect.TypeOf(convSource[key]).Kind() != reflect.TypeOf(data[key]).Kind() {
						return CreateError(ChaincodeError, fmt.Errorf("check parameter type : [%s] parameter require %v, type = %v\n", key, reflect.TypeOf(convSource[key]), reflect.TypeOf(data[key])))
					}
				}
			}
		}
	}

	return nil
}

func CheckType(requireType reflect.Kind, typeParameterFields []string, parameters map[string]interface{}) error {
	for _, typeParameterField := range typeParameterFields {
		// 해당 파라메터가 있는지 확인
		if _, exist := parameters[typeParameterField]; !exist {
			// 해당 파라메터가 없어도 에러처리 하지 않음
		} else {
			// 해당 파라메터가 입력받은 타입인지 확인
			parameter := parameters[typeParameterField]
			if reflect.TypeOf(parameter).Kind() != requireType {
				return CreateError(ChaincodeError, fmt.Errorf("check parameter type : parameter field = %v is not %v, value = %v, type = %v", typeParameterField, requireType, parameter, reflect.TypeOf(parameter)))
			}
		}

	}
	return nil
}

func CheckTypeInt64(typeParameterFields []string, parameters map[string]interface{}) error {
	if err := CheckType(reflect.Float64, typeParameterFields, parameters); err != nil {
		return err
	}

	for _, typeParameterField := range typeParameterFields {
		// 형변환을 통해 해당 파라메터가 int64인지 확인
		value, _ := parameters[typeParameterField].(float64)
		int64Value := int64(value)

		if value != float64(int64Value) {
			return CreateError(ChaincodeError, fmt.Errorf("check parameter type : parameter field = %v is not int64, value = %v, type = %v", typeParameterField, value, reflect.TypeOf(value)))
		}

	}
	return nil
}

func CheckFormatDate(fields []string, parameters map[string]interface{}) error {
	if err := CheckFormatLayout("2006-01-02", fields, parameters); err != nil {
		return err
	}
	return nil
}

func CheckFormatDateAndSecond(fields []string, parameters map[string]interface{}) error {
	if err := CheckFormatLayout("2006-01-02 15:04:05", fields, parameters); err != nil {
		return err
	}
	return nil
}

func CheckFormatLayout(layout string, fields []string, parameters map[string]interface{}) error {
	for _, field := range fields {
		if _, exist := parameters[field]; exist {
			// 입력받은 데이터가 있는 경우 타입 체크
			if _, err := time.Parse(layout, parameters[field].(string)); err != nil {
				return CreateError(ChaincodeError, err)
			}
		}
	}

	return nil
}

func CheckTypeString(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckType(reflect.String, typeParameterFields, parameters)
}

func CheckTypeFloat64(typeParameterFields []string, parameters map[string]interface{}) error {
	return CheckType(reflect.Float64, typeParameterFields, parameters)
}
