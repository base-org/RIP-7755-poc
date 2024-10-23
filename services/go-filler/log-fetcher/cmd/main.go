package main

import (
	"math/big"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/listener"
)

func main() {
	cfg := config.NewConfig() // Load env vars
	srcChain := chains.GetChainConfig(big.NewInt(421614), cfg.RPCs)

	listener.Init(srcChain, cfg)
}
