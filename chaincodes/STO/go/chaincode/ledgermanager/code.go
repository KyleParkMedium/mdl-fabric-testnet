package ledgermanager

const CodeErrorPutState int = 410
const CodeErrorPutStateAlreadyExist int = 411
const CodeErrorGetState int = 420
const CodeErrorGetStateEmptyState int = 421
const CodeErrorGetQueryResultWithPagination int = 430
const CodeErrorGetStateByRange int = 440
const CodeErrorGetStateByRangeEmptyState int = 441
const CodeErrorGetHistoryForKey int = 450
const CodeErrorGetHistoryForKeyEmptyState int = 451
const CodeErrorUpdateState int = 460
const CodeErrorUpdateStateEmptyState int = 461
const CodeErrorDeleteState int = 470
const CodeErrorDeleteStateEmptyState int = 471

const CodeErrorTypeMismatched int = 501

var ErrorCodeMessage = map[int]string{
	CodeErrorPutState:                     "PutState error",
	CodeErrorPutStateAlreadyExist:         "PutState error : Already exist",
	CodeErrorGetState:                     "GetState error",
	CodeErrorGetStateEmptyState:           "GetState error : Empty state",
	CodeErrorGetQueryResultWithPagination: "GetQueryResultWithPagination error",
	CodeErrorGetStateByRange:              "GetStateByRange error",
	CodeErrorGetStateByRangeEmptyState:    "GetStateByRange error : Empty state",
	CodeErrorGetHistoryForKey:             "GetHistoryForKey error",
	CodeErrorGetHistoryForKeyEmptyState:   "GetHistoryForKey error : Empty state",
	CodeErrorUpdateState:                  "UpdateState error",
	CodeErrorUpdateStateEmptyState:        "UpdateState error : Empty state",
	CodeErrorDeleteState:                  "DeleteState error",
	CodeErrorDeleteStateEmptyState:        "DeleteState error : Empty state",
	CodeErrorTypeMismatched:               "DocType error : docType mismatched",
}
