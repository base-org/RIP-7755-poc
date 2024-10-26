package handler

import (
	"errors"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type ParserMock struct {
	mock.Mock
}

type ValidatorMock struct {
	mock.Mock
}

type QueueMock struct {
	mock.Mock
}

func (p *ParserMock) ParseLog(vLog types.Log) (parser.LogCrossChainCallRequested, error) {
	args := p.Called(vLog)
	return args.Get(0).(parser.LogCrossChainCallRequested), args.Error(1)
}

func (v *ValidatorMock) ValidateLog(parsedLog parser.LogCrossChainCallRequested) error {
	args := v.Called(parsedLog)
	return args.Error(0)
}

func (q *QueueMock) Enqueue(parsedLog parser.LogCrossChainCallRequested) error {
	args := q.Called(parsedLog)
	return args.Error(0)
}

func (q *QueueMock) Close() error {
	args := q.Called()
	return args.Error(0)
}

func TestHandler(t *testing.T) {
	parserMock := new(ParserMock)
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	vLog := types.Log{}
	parsedLog := parser.LogCrossChainCallRequested{}

	parserMock.On("ParseLog", vLog).Return(parsedLog, nil)
	validatorMock.On("ValidateLog", parsedLog).Return(nil)
	queueMock.On("Enqueue", parsedLog).Return(nil)

	handler := &handler{parser: parserMock, validator: validatorMock, queue: queueMock}

	err := handler.HandleLog(vLog)

	assert.NoError(t, err)

	parserMock.AssertExpectations(t)
	validatorMock.AssertExpectations(t)
	queueMock.AssertExpectations(t)
}

func TestHandlerReturnsErrorFromParser(t *testing.T) {
	parserMock := new(ParserMock)
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	vLog := types.Log{}

	parserMock.On("ParseLog", vLog).Return(parser.LogCrossChainCallRequested{}, errors.New("test error"))

	handler := &handler{parser: parserMock, validator: validatorMock, queue: queueMock}

	err := handler.HandleLog(vLog)

	assert.Error(t, err)
}

func TestHandlerReturnsErrorFromValidator(t *testing.T) {
	parserMock := new(ParserMock)
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	vLog := types.Log{}
	parsedLog := parser.LogCrossChainCallRequested{}

	parserMock.On("ParseLog", vLog).Return(parsedLog, nil)
	validatorMock.On("ValidateLog", parsedLog).Return(errors.New("test error"))

	handler := &handler{parser: parserMock, validator: validatorMock, queue: queueMock}

	err := handler.HandleLog(vLog)

	assert.Error(t, err)
}

func TestHandlerReturnsErrorFromQueue(t *testing.T) {
	parserMock := new(ParserMock)
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	vLog := types.Log{}
	parsedLog := parser.LogCrossChainCallRequested{}

	parserMock.On("ParseLog", vLog).Return(parsedLog, nil)
	validatorMock.On("ValidateLog", parsedLog).Return(nil)
	queueMock.On("Enqueue", parsedLog).Return(errors.New("test error"))

	handler := &handler{parser: parserMock, validator: validatorMock, queue: queueMock}

	err := handler.HandleLog(vLog)

	assert.Error(t, err)
}
