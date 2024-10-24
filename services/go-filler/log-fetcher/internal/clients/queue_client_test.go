package clients

import (
	"testing"

	internalConfig "github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/stretchr/testify/assert"
)

func TestGetQueueClient(t *testing.T) {
	cfg := &internalConfig.Config{
		RedisQueueUrl: "localhost:6379",
		RedisPassword: "",
	}

	client := GetQueueClient(cfg)
	assert.NotNil(t, client, "Expected non-nil client")
}

// func TestSendMessageToQueue(t *testing.T) {
// 	cfg := &internalConfig.Config{
// 		RedisQueueUrl: "localhost:6379",
// 		RedisPassword: "",
// 	}
// 	// How do I properly mock the client?
// 	client := GetQueueClient(cfg)
// 	parsedLog := parser.LogCrossChainCallRequested{}

// 	err := SendMessageToQueue(parsedLog, cfg, client)

// 	assert.NoError(t, err, "Expected no error")
// }
