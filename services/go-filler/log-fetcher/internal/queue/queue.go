package queue

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	internalConfig "github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
)

func SendMessage(parsedLog parser.LogCrossChainCallRequested, cfg *internalConfig.Config) error {
	fmt.Println("Sending job to queue")

	sdkConfig, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		return err
	}

	sqsClient := sqs.NewFromConfig(sdkConfig)

	job, err := json.Marshal(parsedLog)
	if err != nil {
		return err
	}

	jobStr := string(job)

	params := sqs.SendMessageInput{
		MessageBody: &jobStr,
		QueueUrl:    &cfg.QueueUrl,
	}

	queueRes, err := sqsClient.SendMessage(context.TODO(), &params)
	if err != nil {
		return err
	}

	fmt.Println(queueRes)

	return nil
}
