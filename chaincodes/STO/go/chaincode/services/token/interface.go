package token

type Calc interface {
	AddAmount(amount int64) error
	SubAmount(amount int64) error
}
