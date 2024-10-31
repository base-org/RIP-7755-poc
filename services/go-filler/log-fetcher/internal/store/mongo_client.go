package store

import (
	"context"
	"fmt"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Queue interface {
	Enqueue(*bindings.RIP7755OutboxCrossChainCallRequested) error
	Close() error
}

type MongoCollection interface {
	InsertOne(ctx context.Context, document interface{}, opts ...*options.InsertOneOptions) (*mongo.InsertOneResult, error)
}

type MongoDriverClient interface {
	Database(name string, opts ...*options.DatabaseOptions) *mongo.Database
	Disconnect(context.Context) error
}

type queue struct {
	client     MongoDriverClient
	collection MongoCollection
}

type record struct {
	RequestHash [32]byte
	Request     bindings.CrossChainRequest
}

func NewQueue(cfg *config.Config) (Queue, error) {
	client, err := connect(cfg)
	if err != nil {
		return nil, err
	}

	return &queue{client: client, collection: client.Database("calls").Collection("requests")}, nil
}

func (q *queue) Enqueue(log *bindings.RIP7755OutboxCrossChainCallRequested) error {
	fmt.Println("Sending job to queue")

	r := record{
		RequestHash: log.RequestHash,
		Request:     log.Request,
	}
	_, err := q.collection.InsertOne(context.TODO(), r)
	if err != nil {
		return err
	}

	fmt.Println("Job sent to queue")

	return nil
}

func (q *queue) Close() error {
	return q.client.Disconnect(context.TODO())
}

func connect(cfg *config.Config) (MongoDriverClient, error) {
	fmt.Println("Connecting to MongoDB")
	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(cfg.MongoUri))
	if err != nil {
		return nil, err
	}

	fmt.Println("Connected to MongoDB")

	return client, nil
}
