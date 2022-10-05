package chaincode

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"hash"
	"log"
	"strconv"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"golang.org/x/crypto/sha3"
)

const (
	// Define key names for options
	totalSupplyKey = "totalSupply"
	minterKey      = "minter"
	tokenName      = "mdl"

	// Define objectType names for prefix
	allowancePrefix = "allowance"
	clientPrefix    = "client"

	// AddressLength is the expected length of the address
	addressLength = 20
)

// Errors
var (
	ErrEmptyString   = &decError{"empty hex string"}
	ErrMissingPrefix = &decError{"hex string without 0x prefix"}
	ErrUint64Range   = &decError{"hex number > 64 bits"}
	ErrSyntax        = &decError{"invalid hex string"}
	ErrOddLength     = &decError{"hex string of odd length"}
)

type decError struct{ msg string }

func (err decError) Error() string { return err.msg }

// Address represents the 20 byte address of an Ethereum account.
type Address [addressLength]byte

// SmartContract provides functions for transferring tokens between accounts
type SmartContract struct {
	contractapi.Contract
}

// event provides an organized struct for emitting events
type Event struct {
	From  string
	To    string
	Value int
}

// token
type Token struct {
	Name   string `json:"name"`
	MSPID  string `json:"mspid"`
	Amount int    `json:"amount"`
	Locked bool   `json:"locked"`
}

func (s *SmartContract) Minter(ctx contractapi.TransactionContextInterface, amount int) error {
	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSPID: %v", err)
	}

	minterBytes, err := ctx.GetStub().GetState(minterKey)
	if err != nil {
		return fmt.Errorf("failed to read minter account from world state: %v", err)
	}

	if minterBytes != nil {
		return fmt.Errorf("minter has been already registered: %v", err)
	}

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	// value, found, err := ctx.GetClientIdentity().GetAttributeValue("roles")

	address := getAddress([]byte(id))

	/* Minter를 등록 - Mint, Burn이 가능 */
	err = ctx.GetStub().PutState(minterKey, []byte(address))
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	// Create allowanceKey
	clientKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{address})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}

	clientAmountBytes, err := ctx.GetStub().GetState(clientKey)
	if err != nil {
		return fmt.Errorf("failed to read minter account from world state: %v", err)
	}

	if clientAmountBytes != nil {
		return fmt.Errorf("client %s has been already registered: %v", address, err)
	}

	if amount < 0 {
		return fmt.Errorf("mint amount must be a positive integer")
	}

	token := Token{tokenName, clientMSPID, amount, false}
	tokenJSON, err := json.Marshal(token)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().PutState(clientKey, tokenJSON)
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	log.Printf("minter account %s registered with %s", address, string(tokenJSON))

	return nil
}

func (s *SmartContract) Client(ctx contractapi.TransactionContextInterface) error {
	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSPID: %v", err)
	}

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	// value, found, err := ctx.GetClientIdentity().GetAttributeValue("roles")

	address := getAddress([]byte(id))

	// Create allowanceKey
	clientKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{address})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}

	clientAmountBytes, err := ctx.GetStub().GetState(clientKey)
	if err != nil {
		return fmt.Errorf("failed to read minter account from world state: %v", err)
	}

	if clientAmountBytes != nil {
		return fmt.Errorf("client %s has been already registered: %v", address, err)
	}

	token := Token{tokenName, clientMSPID, 0, false}
	tokenJSON, err := json.Marshal(token)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().PutState(clientKey, tokenJSON)
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	log.Printf("client account %s registered", address)

	return nil
}

// func AddMinter()          // event MinterAdded
// func RenounceMinter()     // event MinterRemoved
// func TransferMinterRole() // event MinterAdded & MinterRemoved

// Mint creates new tokens and adds them to minter's account balance
// This function triggers a Transfer event
func (s *SmartContract) Mint(ctx contractapi.TransactionContextInterface, amount int) error {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSPID: %v", err)
	}

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	minterBytes, err := ctx.GetStub().GetState(minterKey)
	if err != nil {
		return fmt.Errorf("failed to read minter account from world state: %v", err)
	}

	minter := string(minterBytes)
	if minter != getAddress([]byte(id)) {
		return fmt.Errorf("client is not authorized to mint new tokens")
	}

	if amount <= 0 {
		return fmt.Errorf("mint amount must be a positive integer")
	}

	// Create allowanceKey
	clientKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{minter})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}

	tokenBytes, err := ctx.GetStub().GetState(clientKey)
	if err != nil {
		return fmt.Errorf("failed to read minter account %s from world state: %v", minter, err)
	}

	token := new(Token)
	err = json.Unmarshal(tokenBytes, token)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON decoding: %v", err)
	}

	if clientMSPID != token.MSPID {
		return fmt.Errorf("client is not authorized to mint new tokens")
	}

	currentBalance := token.Amount

	updatedBalance := currentBalance + amount

	token.Amount = updatedBalance

	tokenJSON, err := json.Marshal(token)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().PutState(clientKey, tokenJSON)
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	// Update the totalSupply
	totalSupplyBytes, err := ctx.GetStub().GetState(totalSupplyKey)
	if err != nil {
		return fmt.Errorf("failed to retrieve total token supply: %v", err)
	}

	var totalSupply int

	// If no tokens have been minted, initialize the totalSupply
	if totalSupplyBytes == nil {
		totalSupply = 0
	} else {
		totalSupply, _ = strconv.Atoi(string(totalSupplyBytes)) // Error handling not needed since Itoa() was used when setting the totalSupply, guaranteeing it was an integer.
	}

	// Add the mint amount to the total supply and update the state
	totalSupply += amount
	err = ctx.GetStub().PutState(totalSupplyKey, []byte(strconv.Itoa(totalSupply)))
	if err != nil {
		return err
	}

	// Emit the Transfer event
	transferEvent := Event{"0x0", minter, amount}
	transferEventJSON, err := json.Marshal(transferEvent)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().SetEvent("Transfer", transferEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	log.Printf("minter account %s balance updated from %s to %s", minter, string(tokenBytes), string(tokenJSON))

	return nil
}

func getAddress(id []byte) string {
	return Encode(bytesToAddress(Keccak256([]byte(id))[12:]).Bytes())
}

// Burn redeems tokens the minter's account balance
// This function triggers a Transfer event
func (s *SmartContract) Burn(ctx contractapi.TransactionContextInterface, amount int) error {

	// Check minter authorization - this sample assumes Org1 is the central banker with privilege to mint new tokens
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSPID: %v", err)
	}
	if clientMSPID != "Org1MSP" {
		return fmt.Errorf("client is not authorized to mint new tokens")
	}

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	minterBytes, err := ctx.GetStub().GetState(minterKey)
	if err != nil {
		return fmt.Errorf("failed to read minter account from world state: %v", err)
	}

	minter := string(minterBytes)
	if minter != getAddress([]byte(id)) {
		return fmt.Errorf("client is not authorized to mint new tokens")
	}

	if amount <= 0 {
		return fmt.Errorf("mint amount must be a positive integer")
	}

	// Create allowanceKey
	clientKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{minter})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}

	tokenBytes, err := ctx.GetStub().GetState(clientKey)
	if err != nil {
		return fmt.Errorf("failed to read minter account %s from world state: %v", minter, err)
	}
	// Check if minter current balance exists
	if tokenBytes == nil {
		return errors.New("the balance does not exist")
	}

	token := new(Token)
	err = json.Unmarshal(tokenBytes, token)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON decoding: %v", err)
	}

	if clientMSPID != token.MSPID {
		return fmt.Errorf("client is not authorized to mint new tokens")
	}

	currentBalance := token.Amount

	if currentBalance < amount {
		return fmt.Errorf("minter does not have enough balance for burn")
	}

	updatedBalance := currentBalance - amount

	token.Amount = updatedBalance

	tokenJSON, err := json.Marshal(token)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().PutState(clientKey, tokenJSON)
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	// Update the totalSupply
	totalSupplyBytes, err := ctx.GetStub().GetState(totalSupplyKey)
	if err != nil {
		return fmt.Errorf("failed to retrieve total token supply: %v", err)
	}

	// If no tokens have been minted, throw error
	if totalSupplyBytes == nil {
		return errors.New("totalSupply does not exist")
	}

	totalSupply, _ := strconv.Atoi(string(totalSupplyBytes)) // Error handling not needed since Itoa() was used when setting the totalSupply, guaranteeing it was an integer.

	// Subtract the burn amount to the total supply and update the state
	totalSupply -= amount
	err = ctx.GetStub().PutState(totalSupplyKey, []byte(strconv.Itoa(totalSupply)))
	if err != nil {
		return err
	}

	// Emit the Transfer event
	transferEvent := Event{minter, "0x0", amount}
	transferEventJSON, err := json.Marshal(transferEvent)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().SetEvent("Transfer", transferEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	log.Printf("minter account %s balance updated from %s to %s", minter, string(tokenBytes), string(tokenJSON))

	return nil

}

// Transfer transfers tokens from client account to recipient account
// recipient account must be a valid clientID as returned by the ClientID() function
// This function triggers a Transfer event
func (s *SmartContract) Transfer(ctx contractapi.TransactionContextInterface, recipient string, amount int) error {

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	owner := getAddress([]byte(id))

	if amount <= 0 {
		return fmt.Errorf("mint amount must be a positive integer")
	}

	err = transferHelper(ctx, owner, recipient, amount)
	if err != nil {
		return fmt.Errorf("failed to transfer: %v", err)
	}

	// Emit the Transfer event
	transferEvent := Event{owner, recipient, amount}
	transferEventJSON, err := json.Marshal(transferEvent)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().SetEvent("Transfer", transferEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	return nil
}

// BalanceOf returns the balance of the given account
func (s *SmartContract) BalanceOf(ctx contractapi.TransactionContextInterface, account string) (int, error) {
	// Create allowanceKey
	clientKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{account})
	if err != nil {
		return 0, fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}

	balanceBytes, err := ctx.GetStub().GetState(clientKey)
	if err != nil {
		return 0, fmt.Errorf("failed to read from world state: %v", err)
	}

	if balanceBytes == nil {
		return 0, fmt.Errorf("the account %s does not exist", account)
	}

	balance, _ := strconv.Atoi(string(balanceBytes)) // Error handling not needed since Itoa() was used when setting the account balance, guaranteeing it was an integer.

	return balance, nil
}

// ClientAccountBalance returns the balance of the requesting client's account
func (s *SmartContract) ClientAccountBalance(ctx contractapi.TransactionContextInterface) (int, error) {

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return 0, fmt.Errorf("failed to get client id: %v", err)
	}

	owner := getAddress([]byte(id))

	// Create allowanceKey
	ownerKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{owner})
	if err != nil {
		return 0, fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}

	tokenBytes, err := ctx.GetStub().GetState(ownerKey)
	if err != nil {
		return 0, fmt.Errorf("failed to read from world state: %v", err)
	}
	if tokenBytes == nil {
		return 0, fmt.Errorf("the account %s does not exist", owner)
	}

	token := new(Token)
	err = json.Unmarshal(tokenBytes, token)
	if err != nil {
		return 0, fmt.Errorf("failed to obtain JSON decoding: %v", err)
	}

	return token.Amount, nil
}

// ClientAccountID returns the id of the requesting client's account
// In this implementation, the client account ID is the clientId itself
// Users can use this function to get their own account id, which they can then give to others as the payment address
func (s *SmartContract) ClientAccountID(ctx contractapi.TransactionContextInterface) (string, error) {

	// Get ID of submitting client identity
	clientAccountID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return "", fmt.Errorf("failed to get client id: %v", err)
	}
	address := getAddress([]byte(clientAccountID))

	return address, nil
}

func has0xPrefix(input string) bool {
	return len(input) >= 2 && input[0] == '0' && (input[1] == 'x' || input[1] == 'X')
}

func mapError(err error) error {
	if err, ok := err.(*strconv.NumError); ok {
		switch err.Err {
		case strconv.ErrRange:
			return ErrUint64Range
		case strconv.ErrSyntax:
			return ErrSyntax
		}
	}
	if _, ok := err.(hex.InvalidByteError); ok {
		return ErrSyntax
	}
	if err == hex.ErrLength {
		return ErrOddLength
	}
	return err
}

// Decode decodes a hex string with 0x prefix.
func Decode(input string) ([]byte, error) {
	if len(input) == 0 {
		return nil, ErrEmptyString
	}
	if !has0xPrefix(input) {
		return nil, ErrMissingPrefix
	}
	b, err := hex.DecodeString(input[2:])
	if err != nil {
		err = mapError(err)
	}
	return b, err
}

// Encode encodes b as a hex string with 0x prefix.
func Encode(b []byte) string {
	enc := make([]byte, len(b)*2+2)
	copy(enc, "0x")
	hex.Encode(enc[2:], b)
	return string(enc)
}

// KeccakState wraps sha3.state. In addition to the usual hash methods, it also supports
// Read to get a variable amount of data from the hash state. Read is faster than Sum
// because it doesn't copy the internal state, but also modifies the internal state.
type KeccakState interface {
	hash.Hash
	Read([]byte) (int, error)
}

// NewKeccakState creates a new KeccakState
func NewKeccakState() KeccakState {
	return sha3.NewLegacyKeccak256().(KeccakState)
}

// Keccak256 calculates and returns the Keccak256 hash of the input data.
func Keccak256(data ...[]byte) []byte {
	b := make([]byte, 32)
	d := NewKeccakState()
	for _, b := range data {
		d.Write(b)
	}
	d.Read(b)
	return b
}

func bytesToAddress(b []byte) Address {
	var a Address
	a.SetBytes(b)
	return a
}

// SetBytes sets the address to the value of b.
// If b is larger than len(a), b will be cropped from the left.
func (a *Address) SetBytes(b []byte) {
	if len(b) > len(a) {
		b = b[len(b)-addressLength:]
	}
	copy(a[addressLength-len(b):], b)
}

// Bytes gets the string representation of the underlying address.
func (a Address) Bytes() []byte { return a[:] }

// TotalSupply returns the total token supply
func (s *SmartContract) TotalSupply(ctx contractapi.TransactionContextInterface) (int, error) {

	// Retrieve total supply of tokens from state of smart contract
	totalSupplyBytes, err := ctx.GetStub().GetState(totalSupplyKey)
	if err != nil {
		return 0, fmt.Errorf("failed to retrieve total token supply: %v", err)
	}

	var totalSupply int

	// If no tokens have been minted, return 0
	if totalSupplyBytes == nil {
		totalSupply = 0
	} else {
		totalSupply, _ = strconv.Atoi(string(totalSupplyBytes)) // Error handling not needed since Itoa() was used when setting the totalSupply, guaranteeing it was an integer.
	}

	log.Printf("TotalSupply: %d tokens", totalSupply)

	return totalSupply, nil
}

// Approve allows the spender to withdraw from the calling client's token account
// The spender can withdraw multiple times if necessary, up to the value amount
// This function triggers an Approval event
func (s *SmartContract) Approve(ctx contractapi.TransactionContextInterface, spender string, value int) error {

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	owner := getAddress([]byte(id))

	// Create allowanceKey
	allowanceKey, err := ctx.GetStub().CreateCompositeKey(allowancePrefix, []string{owner, spender})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", allowancePrefix, err)
	}

	// Update the state of the smart contract by adding the allowanceKey and value
	err = ctx.GetStub().PutState(allowanceKey, []byte(strconv.Itoa(value)))
	if err != nil {
		return fmt.Errorf("failed to update state of smart contract for key %s: %v", allowanceKey, err)
	}

	// Emit the Approval event
	approvalEvent := Event{owner, spender, value}
	approvalEventJSON, err := json.Marshal(approvalEvent)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().SetEvent("Approval", approvalEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	log.Printf("client %s approved a withdrawal allowance of %d for spender %s", owner, value, spender)

	return nil
}

// Allowance returns the amount still available for the spender to withdraw from the owner
func (s *SmartContract) Allowance(ctx contractapi.TransactionContextInterface, owner string, spender string) (int, error) {

	// Create allowanceKey
	allowanceKey, err := ctx.GetStub().CreateCompositeKey(allowancePrefix, []string{owner, spender})
	if err != nil {
		return 0, fmt.Errorf("failed to create the composite key for prefix %s: %v", allowancePrefix, err)
	}

	// Read the allowance amount from the world state
	allowanceBytes, err := ctx.GetStub().GetState(allowanceKey)
	if err != nil {
		return 0, fmt.Errorf("failed to read allowance for %s from world state: %v", allowanceKey, err)
	}

	var allowance int

	// If no current allowance, set allowance to 0
	if allowanceBytes == nil {
		allowance = 0
	} else {
		allowance, err = strconv.Atoi(string(allowanceBytes)) // Error handling not needed since Itoa() was used when setting the totalSupply, guaranteeing it was an integer.
		if err != nil {
			return 0, fmt.Errorf("failed to convert string to integer: %v", err)
		}
	}

	return allowance, nil
}

// TransferFrom transfers the value amount from the "from" address to the "to" address
// This function triggers a Transfer event
func (s *SmartContract) TransferFrom(ctx contractapi.TransactionContextInterface, from string, to string, value int) error {

	// Get ID of submitting client identity
	id, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client id: %v", err)
	}

	spender := getAddress([]byte(id))

	// Create allowanceKey
	allowanceKey, err := ctx.GetStub().CreateCompositeKey(allowancePrefix, []string{from, spender})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", allowancePrefix, err)
	}

	// Retrieve the allowance of the spender
	currentAllowanceBytes, err := ctx.GetStub().GetState(allowanceKey)
	if err != nil {
		return fmt.Errorf("failed to retrieve the allowance for %s from world state: %v", allowanceKey, err)
	}

	var currentAllowance int
	currentAllowance, _ = strconv.Atoi(string(currentAllowanceBytes)) // Error handling not needed since Itoa() was used when setting the totalSupply, guaranteeing it was an integer.

	// Check if transferred value is less than allowance
	if currentAllowance < value {
		return fmt.Errorf("spender does not have enough allowance for transfer")
	}

	// Initiate the transfer
	err = transferHelper(ctx, from, to, value)
	if err != nil {
		return fmt.Errorf("failed to transfer: %v", err)
	}

	// Decrease the allowance
	updatedAllowance := currentAllowance - value
	err = ctx.GetStub().PutState(allowanceKey, []byte(strconv.Itoa(updatedAllowance)))
	if err != nil {
		return err
	}

	// Emit the Transfer event
	transferEvent := Event{from, to, value}
	transferEventJSON, err := json.Marshal(transferEvent)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().SetEvent("Transfer", transferEventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	log.Printf("spender %s allowance updated from %d to %d", spender, currentAllowance, updatedAllowance)

	return nil
}

// Helper Functions

// transferHelper is a helper function that transfers tokens from the "from" address to the "to" address
// Dependant functions include Transfer and TransferFrom
func transferHelper(ctx contractapi.TransactionContextInterface, from string, to string, value int) error {

	if value < 0 { // transfer of 0 is allowed in ERC-20, so just validate against negative amounts
		return fmt.Errorf("transfer amount cannot be negative")
	}

	// Create allowanceKey
	fromKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{from})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}

	fromTokenBytes, err := ctx.GetStub().GetState(fromKey)
	if err != nil {
		return fmt.Errorf("failed to read client account %s from world state: %v", from, err)
	}

	if fromTokenBytes == nil {
		return fmt.Errorf("from client account %s has no token", from)
	}

	fromToken := new(Token)
	err = json.Unmarshal(fromTokenBytes, fromToken)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON decoding: %v", err)
	}

	fromCurrentBalance := fromToken.Amount

	if fromCurrentBalance < value {
		return fmt.Errorf("client account %s has insufficient funds", from)
	}

	// Create allowanceKey
	toKey, err := ctx.GetStub().CreateCompositeKey(clientPrefix, []string{to})
	if err != nil {
		return fmt.Errorf("failed to create the composite key for prefix %s: %v", clientPrefix, err)
	}
	toTokenBytes, err := ctx.GetStub().GetState(toKey)
	if err != nil {
		return fmt.Errorf("failed to read recipient account %s from world state: %v", to, err)
	}

	if toTokenBytes == nil {
		return fmt.Errorf("to client account %s has no token", from)
	}

	toToken := new(Token)
	err = json.Unmarshal(toTokenBytes, toToken)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON decoding: %v", err)
	}
	toCurrentBalance := toToken.Amount

	fromUpdatedBalance := fromCurrentBalance - value
	fromToken.Amount = fromUpdatedBalance
	fromTokenJSON, err := json.Marshal(fromToken)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().PutState(fromKey, fromTokenJSON)
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}
	toUpdatedBalance := toCurrentBalance + value
	toToken.Amount = toUpdatedBalance
	toTokenJSON, err := json.Marshal(toToken)
	if err != nil {
		return fmt.Errorf("failed to obtain JSON encoding: %v", err)
	}
	err = ctx.GetStub().PutState(toKey, toTokenJSON)
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	log.Printf("client %s balance updated from %s to %s", from, string(fromTokenBytes), string(fromTokenJSON))
	log.Printf("recipient %s balance updated from %s to %s", to, string(toTokenBytes), string(toTokenJSON))

	return nil
}
