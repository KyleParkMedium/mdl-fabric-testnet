package token

const (
	FieldPartition   string = "partition"
	FieldTokenHolder string = "tokenHolder"

	FieldAmount string = "amount"

	FieldOwner   string = "owner"
	FieldSpender string = "spender"

	FieldRecipient string = "recipient"

	FieldFrom string = "from"
	FieldTo   string = "to"

	FieldTokenWalletId string = "tokenWalletId"
	FieldRole          string = "role"
	FieldAccountNumber string = "accountNumber"

	// issueToken
	FieldTokenId              string = "tokenId"
	FieldPublisher            string = "publisher"
	FieldPublisherUuid        string = "publisherUuid"
	FieldRor                  string = "ror"
	FieldInvestmentPeriod     string = "investmentPeriod"
	FieldGrade                string = "grade"
	FieldPublicOfferingAmount string = "publicOfferingAmount"
	FieldStartDate            string = "startDate"
	FieldEndDate              string = "endDate"

	FieldCaller string = "caller"

	// Query
	FieldIsLocked      string = "isLocked"
	FieldIsDistributed string = "isDistributed"
	FieldIsRedeemed    string = "isRedeemed"

	FieldPartitionTokens string = "partitionTokens"
)
