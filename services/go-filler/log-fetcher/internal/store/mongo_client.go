package store

import (
	"context"
	"fmt"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MongoClient interface {
	Close() error
	Collection(name string) MongoConnection
}

type MongoConnection interface {
	Enqueue(parsedLog parser.LogCrossChainCallRequested, cfg *config.Config) error
}

type MongoCollection interface {
	InsertOne(ctx context.Context, document interface{}, opts ...*options.InsertOneOptions) (*mongo.InsertOneResult, error)
}

type MongoDriverClient interface {
	Database(name string, opts ...*options.DatabaseOptions) *mongo.Database
	Disconnect(context.Context) error
}

type mongoClient struct {
	client MongoDriverClient
}
type mongoConnection struct {
	collection MongoCollection
}

func NewMongoClient(cfg *config.Config) (MongoClient, error) {
	fmt.Println("Connecting to MongoDB")
	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(cfg.MongoUri))
	if err != nil {
		return nil, err
	}

	fmt.Println("Connected to MongoDB")

	return &mongoClient{client: client}, nil
}

func (c *mongoClient) Collection(name string) MongoConnection {
	return &mongoConnection{collection: c.client.Database("calls").Collection(name)}
}

func (c *mongoConnection) Enqueue(parsedLog parser.LogCrossChainCallRequested, cfg *config.Config) error {
	fmt.Println("Sending job to queue")

	_, err := c.collection.InsertOne(context.TODO(), parsedLog)
	if err != nil {
		return err
	}

	fmt.Println("Job sent to queue")

	return nil
}

func (c *mongoClient) Close() error {
	return c.client.Disconnect(context.TODO())
}
