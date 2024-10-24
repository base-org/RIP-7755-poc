package clients

import (
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/hibiken/asynq"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type AsynqClientMock struct {
	mock.Mock
}

func (m *AsynqClientMock) Enqueue(task *asynq.Task, opts ...asynq.Option) (*asynq.TaskInfo, error) {
	args := m.Called(task, opts)
	return args.Get(0).(*asynq.TaskInfo), args.Error(1)
}

func TestSendMessageToQueue(t *testing.T) {
	mockClient := new(AsynqClientMock)
	queueClient := &queueClient{client: mockClient}

	mockClient.On("Enqueue", mock.Anything, mock.Anything).Return(&asynq.TaskInfo{}, nil)

	err := queueClient.SendMessageToQueue(parser.LogCrossChainCallRequested{}, &config.Config{})

	assert.NoError(t, err)
}
