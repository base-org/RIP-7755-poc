package handler

import (
	"errors"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type ValidatorMock struct {
	mock.Mock
}

type QueueMock struct {
	mock.Mock
}

func (v *ValidatorMock) ValidateLog(log *bindings.RIP7755OutboxCrossChainCallRequested) error {
	args := v.Called(log)
	return args.Error(0)
}

func (q *QueueMock) Enqueue(log *bindings.RIP7755OutboxCrossChainCallRequested) error {
	args := q.Called(log)
	return args.Error(0)
}

func (q *QueueMock) ReadCheckpoint(checkpointId string) (uint64, error) {
	args := q.Called(checkpointId)
	return args.Get(0).(uint64), args.Error(1)
}

func (q *QueueMock) WriteCheckpoint(checkpointId string, blockNumber uint64) error {
	args := q.Called(checkpointId, blockNumber)
	return args.Error(0)
}

func (q *QueueMock) Close() error {
	args := q.Called()
	return args.Error(0)
}

func TestHandler(t *testing.T) {
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	log := &bindings.RIP7755OutboxCrossChainCallRequested{}

	validatorMock.On("ValidateLog", log).Return(nil)
	queueMock.On("Enqueue", log).Return(nil)
	queueMock.On("WriteCheckpoint", "test", log.Raw.BlockNumber).Return(nil)
	handler := &handler{validator: validatorMock, queue: queueMock}

	err := handler.HandleLog("test", log)

	assert.NoError(t, err)

	validatorMock.AssertExpectations(t)
	queueMock.AssertExpectations(t)
}

func TestHandlerReturnsErrorFromValidator(t *testing.T) {
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	log := &bindings.RIP7755OutboxCrossChainCallRequested{}

	validatorMock.On("ValidateLog", log).Return(errors.New("test error"))

	handler := &handler{validator: validatorMock, queue: queueMock}

	err := handler.HandleLog("test", log)

	assert.Error(t, err)
}

func TestHandlerReturnsErrorFromQueue(t *testing.T) {
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	log := &bindings.RIP7755OutboxCrossChainCallRequested{}

	validatorMock.On("ValidateLog", log).Return(nil)
	queueMock.On("Enqueue", log).Return(errors.New("test error"))

	handler := &handler{validator: validatorMock, queue: queueMock}

	err := handler.HandleLog("test", log)

	assert.Error(t, err)
}

func TestHandlerReturnsErrorFromWriteCheckpoint(t *testing.T) {
	validatorMock := new(ValidatorMock)
	queueMock := new(QueueMock)

	log := &bindings.RIP7755OutboxCrossChainCallRequested{}

	validatorMock.On("ValidateLog", log).Return(nil)
	queueMock.On("Enqueue", log).Return(nil)
	queueMock.On("WriteCheckpoint", "test", log.Raw.BlockNumber).Return(errors.New("test error"))

	handler := &handler{validator: validatorMock, queue: queueMock}

	err := handler.HandleLog("test", log)

	assert.Error(t, err)
}
