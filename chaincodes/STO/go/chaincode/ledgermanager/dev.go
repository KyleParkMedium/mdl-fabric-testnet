package ledgermanager

import (
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/the-medium-tech/mdl-chaincodes/chaincode/ccutils"
)

type Ex struct {
	Name string
}

func (e *Ex) PutState(docType string, key string, data interface{}, ctx contractapi.TransactionContextInterface) (string, error) {
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

	// 이거 엔도서에서 에러날 수 있음
	// if value, _ := dataMap[ID]; value == "" {
	// 	dataMap[ID] = ccutils.GenerateUniqueID(64)
	// }

	// time format binding 문제로 임시 주석 처리
	if value, _ := dataMap[CreatedDate]; value == "" {
		dataMap[CreatedDate] = ccutils.CreateKstTimeAndSecond()
	} else {
		err := ccutils.CheckFormatDateAndSecond([]string{CreatedDate}, dataMap)
		if err != nil {
			return "", err
		}
	}

	dataMap[UpdatedDate] = dataMap[CreatedDate]
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

func (e *Ex) GetState(docType string, key string, ctx contractapi.TransactionContextInterface) ([]byte, error) {
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

func (e *Ex) UpdateState(docType string, key string, data map[string]interface{}, ctx contractapi.TransactionContextInterface) error {
	var asIsDataBytes []byte
	var err error
	if asIsDataBytes, err = GetState(docType, key, ctx); err != nil {
		return err
	}

	if data == nil {
		return ccutils.CreateError(CodeErrorUpdateStateEmptyState, fmt.Errorf(ErrorCodeMessage[CodeErrorUpdateStateEmptyState]+" : "+key))
	}

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

	asIsMap[UpdatedDate] = ccutils.CreateKstTimeAndSecond()
	// // updatedDate가 없으면 입력
	// if _, exist := toBeMap[UpdatedDate]; !exist {
	// 	asIsMap[UpdatedDate] = ccutils.CreateKstTimeAndSecond()
	// } else {
	// 	asIsMap[UpdatedDate] = toBeMap[UpdatedDate]
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
