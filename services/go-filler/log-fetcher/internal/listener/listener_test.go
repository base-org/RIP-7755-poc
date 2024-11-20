package listener

import (
	"math/big"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/stretchr/testify/assert"
)

type cliContext struct{}

func (c *cliContext) String(name string) string {
	return "https://arbitrum-sepolia.com"
}

var queue store.Queue

func TestNewListener(t *testing.T) {
	l, err := NewListener(big.NewInt(421614), &cliContext{}, queue)
	if err != nil {
		t.Fatalf("Failed to create listener: %v", err)
	}

	assert.NotNil(t, l)
}
