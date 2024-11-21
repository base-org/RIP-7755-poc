package listener

import (
	"math/big"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
)

var networksCfg chains.NetworksConfig = chains.NetworksConfig{
	Networks: chains.Networks{
		"421614": chains.ChainConfig{
			RpcUrl: "https://arb-sepolia.example.com",
			Contracts: &chains.Contracts{
				Outbox: common.HexToAddress("0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2"),
			},
		},
	},
}

var queue store.Queue

func TestNewListener(t *testing.T) {
	l, err := NewListener(big.NewInt(421614), networksCfg.Networks, queue)
	if err != nil {
		t.Fatalf("Failed to create listener: %v", err)
	}

	assert.NotNil(t, l)
}
