package flogging

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// MustGetLogger creates a logger with the specified name. If an invalid name
// is provided, the operation will panic.
func MustGetLogger(loggerName string) *FabricLogger {
	return Logger(loggerName)
}

// Logger instantiates a new FabricLogger with the specified name. The name is
// used to determine which log levels are enabled.
func Logger(name string) *FabricLogger {
	zl := ZapLogger(name)
	return NewFabricLogger(zl)
}

// ZapLogger instantiates a new zap.Logger with the specified name. The name is
// used to determine which log levels are enabled.
func ZapLogger(name string) *zap.Logger {

	// if !isValidLoggerName(name) {
	// 	panic(fmt.Sprintf("invalid logger name: %s", name))
	// }

	// a, _ := zap.NewProduction()
	a, _ := zap.NewDevelopment()
	return a

	// return NewZapLogger(nil).Named(name)
}

// NewFabricLogger creates a logger that delegates to the zap.SugaredLogger.
func NewFabricLogger(l *zap.Logger, options ...zap.Option) *FabricLogger {
	return &FabricLogger{
		s: l.WithOptions(append(options, zap.AddCallerSkip(1))...).Sugar(),
	}
}

func NewZapLogger(core zapcore.Core, options ...zap.Option) *zap.Logger {
	return zap.New(
		core,
		append([]zap.Option{
			zap.AddCaller(),
			zap.AddStacktrace(zapcore.ErrorLevel),
		}, options...)...,
	)
}
