package operator

const (
	DocType_Operator = "DOCTYPE_OPERATOR"
)

type OperatorsStruct struct {
	DocType string `json:"docType"`

	Operator map[string]map[string]OperatorStruct `json:"operator"`

	CreatedDate string `json:"createdDate"`
	UpdatedDate string `json:"updatedDate"`
}

type OperatorStruct struct {
	DocType string `json:"docType"`

	Name string `json:"name"`
	Role string `json:"role"`
}
