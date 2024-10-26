package listener

import (
	"math/big"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/stretchr/testify/assert"
)

var cfg *config.Config = &config.Config{
	RPCs: &config.RPCs{
		ArbitrumSepolia: "https://arbitrum-sepolia.com",
	},
}
var queue store.Queue

func TestNewListener(t *testing.T) {
	srcChain, err := chains.GetChainConfig(big.NewInt(421614), cfg.RPCs)
	if err != nil {
		t.Fatalf("Failed to create source chain: %v", err)
	}

	l, err := NewListener(srcChain, cfg, queue)
	if err != nil {
		t.Fatalf("Failed to create listener: %v", err)
	}

	assert.NotNil(t, l)
}
