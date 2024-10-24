package clients

import (
	"encoding/json"
	"fmt"

	internalConfig "github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/hibiken/asynq"
)

type QueueClient interface {
	SendMessageToQueue(parsedLog parser.LogCrossChainCallRequested, cfg *internalConfig.Config) error
}
type AsynqClient interface {
	Enqueue(task *asynq.Task, opts ...asynq.Option) (*asynq.TaskInfo, error)
}

type queueClient struct {
	client AsynqClient
}

func GetQueueClient(cfg *internalConfig.Config) QueueClient {
	redisConnOpt := asynq.RedisClientOpt{
		Addr:     cfg.RedisQueueUrl,
		Password: cfg.RedisPassword,
		DB:       2,
	}
	return &queueClient{client: asynq.NewClient(redisConnOpt)}
}

func (c *queueClient) SendMessageToQueue(parsedLog parser.LogCrossChainCallRequested, cfg *internalConfig.Config) error {
	fmt.Println("Sending job to queue")

	// Task is created with two parameters: its type and payload.
	// Payload data is simply an array of bytes. It can be encoded in JSON, Protocol Buffer, Gob, etc.
	b, err := json.Marshal(parsedLog)
	if err != nil {
		return err
	}

	task := asynq.NewTask("call-requested", b)

	// Enqueue the task to be processed immediately.
	_, err = c.client.Enqueue(task)
	if err != nil {
		return err
	}

	fmt.Println("Job sent to queue")

	return nil
}
