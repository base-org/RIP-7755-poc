package store

import (
	"context"
	"errors"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
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
	mongoConnection := &mongoConnection{collection: mockConnection}

	mockConnection.On("InsertOne", mock.Anything, mock.Anything, mock.Anything).Return(&mongo.InsertOneResult{}, nil)

	err := mongoConnection.Enqueue(parser.LogCrossChainCallRequested{}, &config.Config{})

	assert.NoError(t, err)
}

func TestEnqueuePassesParsedLogToInsertOne(t *testing.T) {
	mockConnection := new(MongoConnectionMock)
	mongoConnection := &mongoConnection{collection: mockConnection}
	parsedLog := parser.LogCrossChainCallRequested{}

	mockConnection.On("InsertOne", context.TODO(), parsedLog, mock.Anything).Return(&mongo.InsertOneResult{}, nil)

	err := mongoConnection.Enqueue(parsedLog, &config.Config{})

	assert.NoError(t, err)
	mockConnection.AssertExpectations(t)
}

func TestEnqueueError(t *testing.T) {
	mockConnection := new(MongoConnectionMock)
	mongoConnection := &mongoConnection{collection: mockConnection}

	mockConnection.On("InsertOne", mock.Anything, mock.Anything, mock.Anything).Return(&mongo.InsertOneResult{}, errors.New("error"))

	err := mongoConnection.Enqueue(parser.LogCrossChainCallRequested{}, &config.Config{})

	assert.Error(t, err)
}

func TestClose(t *testing.T) {
	mockClient := new(MongoClientMock)
	mongoClient := &mongoClient{client: mockClient}

	mockClient.On("Disconnect", context.TODO()).Return(nil)

	err := mongoClient.Close()

	assert.NoError(t, err)
}

func TestCloseError(t *testing.T) {
	mockClient := new(MongoClientMock)
	mongoClient := &mongoClient{client: mockClient}

	mockClient.On("Disconnect", context.TODO()).Return(errors.New("error"))

	err := mongoClient.Close()

	assert.Error(t, err)
}
