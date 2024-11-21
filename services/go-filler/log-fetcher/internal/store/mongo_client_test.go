package store

import (
	"context"
	"errors"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MongoClientMock struct {
	mock.Mock
}

type MongoConnectionMock struct {
	mock.Mock
}

func (c *MongoConnectionMock) InsertOne(ctx context.Context, document interface{}, opts ...*options.InsertOneOptions) (*mongo.InsertOneResult, error) {
	args := c.Called(ctx, document, opts)
	return args.Get(0).(*mongo.InsertOneResult), args.Error(1)
}

func (c *MongoConnectionMock) UpdateOne(ctx context.Context, filter interface{}, update interface{}, opts ...*options.UpdateOptions) (*mongo.UpdateResult, error) {
	args := c.Called(ctx, filter, update, opts)
	return args.Get(0).(*mongo.UpdateResult), args.Error(1)
}

func (c *MongoConnectionMock) FindOne(ctx context.Context, filter interface{}, opts ...*options.FindOneOptions) *mongo.SingleResult {
	args := c.Called(ctx, filter, opts)
	return args.Get(0).(*mongo.SingleResult)
}

func (m *MongoClientMock) Database(name string, opts ...*options.DatabaseOptions) *mongo.Database {
	args := m.Called(name, opts)
	return args.Get(0).(*mongo.Database)
}

func (m *MongoClientMock) Disconnect(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func TestEnqueue(t *testing.T) {
	mockConnection := new(MongoConnectionMock)
	queue := &queue{collection: mockConnection}

	mockConnection.On("InsertOne", mock.Anything, mock.Anything, mock.Anything).Return(&mongo.InsertOneResult{}, nil)

	err := queue.Enqueue(&bindings.RIP7755OutboxCrossChainCallRequested{})

	assert.NoError(t, err)
}

func TestEnqueuePassesParsedLogToInsertOne(t *testing.T) {
	mockConnection := new(MongoConnectionMock)
	queue := &queue{collection: mockConnection}
	log := &bindings.RIP7755OutboxCrossChainCallRequested{}
	r := record{
		RequestHash: log.RequestHash,
		Request:     log.Request,
	}

	mockConnection.On("InsertOne", context.TODO(), r, mock.Anything).Return(&mongo.InsertOneResult{}, nil)

	err := queue.Enqueue(log)

	assert.NoError(t, err)
	mockConnection.AssertExpectations(t)
}

func TestEnqueueError(t *testing.T) {
	mockConnection := new(MongoConnectionMock)
	queue := &queue{collection: mockConnection}

	mockConnection.On("InsertOne", mock.Anything, mock.Anything, mock.Anything).Return(&mongo.InsertOneResult{}, errors.New("error"))

	err := queue.Enqueue(&bindings.RIP7755OutboxCrossChainCallRequested{})

	assert.Error(t, err)
}

func TestReadCheckpoint(t *testing.T) {
	mockConnection := new(MongoConnectionMock)
	queue := &queue{checkpoint: mockConnection}

	mockConnection.On("FindOne", mock.Anything, mock.Anything, mock.Anything).Return(&mongo.SingleResult{})

	checkpoint, err := queue.ReadCheckpoint("test")

	assert.NoError(t, err)
	assert.Equal(t, uint64(0), checkpoint)
	mockConnection.AssertExpectations(t)
}

func TestWriteCheckpoint(t *testing.T) {
	mockConnection := new(MongoConnectionMock)
	queue := &queue{checkpoint: mockConnection}

	mockConnection.On("UpdateOne", mock.Anything, mock.Anything, mock.Anything, mock.Anything).Return(&mongo.UpdateResult{}, nil)

	err := queue.WriteCheckpoint("test", 1)

	assert.NoError(t, err)
	mockConnection.AssertExpectations(t)
}

func TestClose(t *testing.T) {
	mockClient := new(MongoClientMock)
	queue := &queue{client: mockClient}

	mockClient.On("Disconnect", context.TODO()).Return(nil)

	err := queue.Close()

	assert.NoError(t, err)
}

func TestCloseError(t *testing.T) {
	mockClient := new(MongoClientMock)
	queue := &queue{client: mockClient}

	mockClient.On("Disconnect", context.TODO()).Return(errors.New("error"))

	err := queue.Close()

	assert.Error(t, err)
}
