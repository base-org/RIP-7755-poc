package store

import (
	"context"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	logger "github.com/ethereum/go-ethereum/log"
	"github.com/urfave/cli/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Queue interface {
	Enqueue(*bindings.RIP7755OutboxCrossChainCallRequested) error
	ReadCheckpoint(checkpointId string) (uint64, error)
	WriteCheckpoint(checkpointId string, blockNumber uint64) error
	Close() error
}

type MongoCollection interface {
	InsertOne(ctx context.Context, document interface{}, opts ...*options.InsertOneOptions) (*mongo.InsertOneResult, error)
	UpdateOne(ctx context.Context, filter interface{}, update interface{}, opts ...*options.UpdateOptions) (*mongo.UpdateResult, error)
	FindOne(ctx context.Context, filter interface{}, opts ...*options.FindOneOptions) *mongo.SingleResult
}

type MongoDriverClient interface {
	Database(name string, opts ...*options.DatabaseOptions) *mongo.Database
	Disconnect(context.Context) error
}

type queue struct {
	client     MongoDriverClient
	collection MongoCollection
	checkpoint MongoCollection
}

type record struct {
	RequestHash [32]byte
	Request     bindings.CrossChainRequest
}

type checkpoint struct {
	BlockNumber uint64
}

func NewQueue(ctx *cli.Context) (Queue, error) {
	client, err := connect(ctx)
	if err != nil {
		return nil, err
	}

	return &queue{client: client, collection: client.Database("calls").Collection("requests"), checkpoint: client.Database("calls").Collection("checkpoint")}, nil
}

func (q *queue) Enqueue(log *bindings.RIP7755OutboxCrossChainCallRequested) error {
	logger.Info("Sending job to queue")

	r := record{
		RequestHash: log.RequestHash,
		Request:     log.Request,
	}
	_, err := q.collection.InsertOne(context.TODO(), r)
	if err != nil {
		return err
	}

	logger.Info("Job sent to queue")

	return nil
}

func (q *queue) ReadCheckpoint(checkpointId string) (uint64, error) {
	res := q.checkpoint.FindOne(context.TODO(), bson.M{"id": checkpointId})
	if res.Err() != nil {
		// If the checkpoint doesn't exist, return 0 as starting block
		if res.Err() == mongo.ErrNoDocuments {
			return 0, nil
		}
		return 0, res.Err()
	}

	var c checkpoint
	if err := res.Decode(&c); err != nil {
		return 0, err
	}

	return c.BlockNumber, nil
}

func (q *queue) WriteCheckpoint(checkpointId string, blockNumber uint64) error {
	c := checkpoint{
		BlockNumber: blockNumber,
	}
	opts := options.Update().SetUpsert(true)
	_, err := q.checkpoint.UpdateOne(context.TODO(), bson.M{"id": checkpointId}, bson.M{"$set": c}, opts)
	if err != nil {
		return err
	}

	return nil
}

func (q *queue) Close() error {
	return q.client.Disconnect(context.TODO())
}

func connect(ctx *cli.Context) (MongoDriverClient, error) {
	logger.Info("Connecting to MongoDB")
	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(ctx.String("mongo-uri")))
	if err != nil {
		return nil, err
	}

	logger.Info("Connected to MongoDB")

	return client, nil
}
