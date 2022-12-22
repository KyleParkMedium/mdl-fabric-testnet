package operator

const (
	DocType_Operator = "DOCTYPE_OPERATOR"
)

type OperatorsStruct struct {
	DocType string `json:"docType"`

	Operator map[string]OperatorStruct `json:"operator"`
}

type OperatorStruct struct {
	DocType string `json:"docType"`

	Name string `json:"name"`
	Role string `json:"role"`
}
