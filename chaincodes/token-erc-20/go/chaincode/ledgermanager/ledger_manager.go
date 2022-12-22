package ledgermanager

import (
	"bytes"
	"encoding/json"
	"fmt"
	"reflect"
	"strconv"

	"github.com/KyleParkMedium/mdl-chaincode/chaincode/ccutils"
	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/op/go-logging"
)

var logger = logging.MustGetLogger("ledgermanager")

func PutState(docType string, key string, data interface{}, ctx contractapi.TransactionContextInterface) (string, error) {
	if reflect.TypeOf(data).Kind() != reflect.Struct {
		return "", ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("check parameter type : parameter data is not struct, type = %v", reflect.TypeOf(data)))
	}

	exist, err := CheckExistState(key, ctx)
	// 에러 체크
	if err != nil {
		return "", err
	}

	// 이미 존재하는지 체크
	if exist {
		return "", ccutils.CreateError(CodeErrorPutStateAlreadyExist, fmt.Errorf(ErrorCodeMessage[CodeErrorPutStateAlreadyExist]+" : "+key))
	}

	dataMap, err := ccutils.StructToMap(data)
	if err != nil {
		return "", err
	}
	dataMap[DocType] = docType

	if value, _ := dataMap[ID]; value == "" {
		dataMap[ID] = ccutils.GenerateUniqueID(64)
	}

	// time format binding 문제로 임시 주석 처리
	// if value, _ := dataMap[CreatedDate]; value == "" {
	// 	dataMap[CreatedDate] = ccutils.CreateKstTimeAndSecond()
	// } else {
	// 	err := ccutils.CheckFormatDateAndSecond([]string{CreatedDate}, dataMap)
	// 	if err != nil {
	// 		return "", err
	// 	}
	// }

	// dataMap[UpdatedDate] = dataMap[CreatedDate]
	dataMap[TxId] = ctx.GetStub().GetTxID()

	var dataBytes []byte
	// dataBytes, err = json.Marshal(data)

	if dataBytes, err = json.Marshal(dataMap); err != nil {
		return "", ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	if err := ctx.GetStub().PutState(key, dataBytes); err != nil {
		return "", ccutils.CreateError(ccutils.ChaincodeError, err)
	}
	return key, nil
}

func GetState(docType string, key string, ctx contractapi.TransactionContextInterface) ([]byte, error) {
	var resultBytes []byte
	var err error
	if resultBytes, err = GetExistState(key, ctx); err != nil {
		return nil, err
	}

	// docType 확인
	resultMap := make(map[string]interface{})
	err = json.Unmarshal(resultBytes, &resultMap)
	if err != nil {
		return nil, ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	if resultMap[DocType] != docType {
		return nil, ccutils.CreateError(CodeErrorTypeMismatched, fmt.Errorf(ErrorCodeMessage[CodeErrorTypeMismatched]+" : "+docType))
	}

	return resultBytes, nil
}

func UpdateState(docType string, key string, data map[string]interface{}, ctx contractapi.TransactionContextInterface) error {
	var asIsDataBytes []byte
	var err error
	if asIsDataBytes, err = GetState(docType, key, ctx); err != nil {
		return err
	}

	// 이거 일단 주석 처리 해서 경과 파악 필요 없는 코드 인데
	// // 존재하지 않는 키값
	// if asIsDataBytes == nil {
	// 	return ccutils.CreateError(CodeErrorUpdateStateEmptyState, fmt.Errorf(ErrorCodeMessage[CodeErrorUpdateStateEmptyState]+" : "+key))
	// }

	asIsMap := make(map[string]interface{})
	err = json.Unmarshal(asIsDataBytes, &asIsMap)
	if err != nil {
		return ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	// 데이터를 바이트로 마샬링하여 바이트 배열로 만듦
	var toBeDataBytes []byte
	if toBeDataBytes, err = json.Marshal(data); err != nil {
		return ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	toBeMap := make(map[string]interface{})
	err = json.Unmarshal(toBeDataBytes, &toBeMap)
	if err != nil {
		return ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	for key := range toBeMap {
		if _, exist := asIsMap[key]; exist {
			// 기존에 있는 필드면 데이터형 체크
			if reflect.TypeOf(asIsMap[key]).Kind() != reflect.TypeOf(toBeMap[key]).Kind() {
				return ccutils.CreateError(ccutils.ChaincodeError, fmt.Errorf("check parameter type : [%s] parameter require %v, type = %v\n", key, reflect.TypeOf(asIsMap[key]), reflect.TypeOf(toBeMap[key])))
			}
		}
		asIsMap[key] = toBeMap[key]
	}

	// 외부에서 docType을 수정하지 못하도록 강제
	if _, exist := toBeMap[DocType]; exist {
		asIsMap[DocType] = docType
	}

	// // updatedDate가 없으면 입력
	// if _, exist := toBeMap[UpdatedDate]; !exist {
	// 	asIsMap[UpdatedDate] = ccutils.CreateKstTimeAndSecond()
	// } else {
	// 	err := ccutils.CheckFormatDateAndSecond([]string{UpdatedDate}, asIsMap)
	// 	if err != nil {
	// 		return err
	// 	}
	// }

	if asIsDataBytes, err = json.Marshal(asIsMap); err != nil {
		return ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	// 마샬링한 바이트 배열을 원장에 기록
	if err := ctx.GetStub().PutState(key, asIsDataBytes); err != nil {
		return ccutils.CreateError(ccutils.ChaincodeError, err)
	}
	return nil
}

func GetExistState(key string, ctx contractapi.TransactionContextInterface) ([]byte, error) {
	var resultBytes []byte
	var err error
	if resultBytes, err = ctx.GetStub().GetState(key); err != nil {
		return nil, ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	// 키값이 존재하지 않는 경우
	if resultBytes == nil {
		return nil, ccutils.CreateError(CodeErrorGetStateEmptyState, fmt.Errorf(ErrorCodeMessage[CodeErrorGetStateEmptyState]+" : "+key))
	}

	return resultBytes, nil
}

func CheckExistState(key string, ctx contractapi.TransactionContextInterface) (bool, error) {
	var resultBytes []byte
	var err error
	if resultBytes, err = ctx.GetStub().GetState(key); err != nil {
		return false, ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	// 키값이 존재하지 않는 경우
	if resultBytes == nil {
		return false, nil
	}

	return true, nil
}

func GetQueryResultWithPagination(queryString string, pageSize int32, bookmark string, ctx contractapi.TransactionContextInterface) ([]byte, error) {
	//logger.Info("queryString = ", queryString)

	resultsIterator, metadata, err := ctx.GetStub().GetQueryResultWithPagination(queryString, pageSize, bookmark)
	if err != nil {
		return nil, ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	var buffer *bytes.Buffer
	if resultsIterator != nil {
		buffer, err = constructQueryResponseFromIterator(resultsIterator)
		if err != nil {
			return nil, ccutils.CreateError(ccutils.ChaincodeError, err)
		}
	} else {
		retEmptyDataList := `{"` + FieldDatalist + `":[], "` + FieldRecordsCount + `" : ` + strconv.Itoa(int(metadata.FetchedRecordsCount)) + `, "` + FieldBookmark + `" : ""}`
		return []byte(retEmptyDataList), nil
	}

	// 원본
	//retData := `{"datalist":` + buffer.String() + `, "metadata" : {"recordsCount" : ` + strconv.Itoa(int(metadata.FetchedRecordsCount)) + `, "bookmark" : "` + metadata.Bookmark + `"}}`
	retData := ""
	if metadata.FetchedRecordsCount < pageSize {
		retData = `{"` + FieldDatalist + `":` + buffer.String() + `, "` + FieldRecordsCount + `" : ` + strconv.Itoa(int(metadata.FetchedRecordsCount)) + `, "` + FieldBookmark + `" : ""}`
	} else {
		retData = `{"` + FieldDatalist + `":` + buffer.String() + `, "` + FieldRecordsCount + `" : ` + strconv.Itoa(int(metadata.FetchedRecordsCount)) + `, "` + FieldBookmark + `" : "` + metadata.Bookmark + `"}`
	}

	return []byte(retData), nil
}

// ===========================================================================================
// constructQueryResponseFromIterator constructs a JSON array containing query results from
// a given result iterator
// ===========================================================================================
func constructQueryResponseFromIterator(resultsIterator shim.StateQueryIteratorInterface) (*bytes.Buffer, error) {
	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}

		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	return &buffer, nil
}

func GetStateByRange(startKey string, endKey string, ctx contractapi.TransactionContextInterface) ([]byte, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)
	if err != nil {
		return nil, ccutils.CreateError(ccutils.ChaincodeError, err)
	}
	defer func(resultsIterator shim.StateQueryIteratorInterface) {
		err := resultsIterator.Close()
		if err != nil {

		}
	}(resultsIterator)

	buffer, err := constructQueryResponseFromIterator(resultsIterator)
	if err != nil {
		return nil, ccutils.CreateError(ccutils.ChaincodeError, err)
	}

	return buffer.Bytes(), nil
}
