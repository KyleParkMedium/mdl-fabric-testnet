package ccutils

const (
	ChaincodeSuccess            = 200
	ChaincodeError              = 400
	ChaincodeErrorNotFoundAPI   = 401
	ChaincodeServiceUnavailable = 503
)

var CodeMessage = map[int]string{
	ChaincodeSuccess:            "Success",
	ChaincodeError:              "Error",
	ChaincodeErrorNotFoundAPI:   "Not found API",
	ChaincodeServiceUnavailable: "Chaincode Service Unavailable",
}
