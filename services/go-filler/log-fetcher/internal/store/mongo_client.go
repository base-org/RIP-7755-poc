package store

import (
	"context"
	"fmt"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Queue interface {
	Enqueue(parsedLog parser.LogCrossChainCallRequested) error
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

func NewQueue(cfg *config.Config) (Queue, error) {
	client, err := connect(cfg)
	if err != nil {
		return nil, err
	}

	return &queue{client: client, collection: client.Database("calls").Collection("requests")}, nil
}

func (q *queue) Enqueue(parsedLog parser.LogCrossChainCallRequested) error {
	fmt.Println("Sending job to queue")

	_, err := q.collection.InsertOne(context.TODO(), parsedLog)
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
