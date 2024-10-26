package main

import (
	"log"
	"math/big"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/listener"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
)

var supportedChains = []*big.Int{big.NewInt(421614)}

func main() {
	cfg, err := config.NewConfig() // Load env vars
	if err != nil {
		log.Fatal(err)
	}

	queue, err := store.NewQueue(cfg)
	if err != nil {
		log.Fatal(err)
	}
	defer queue.Close()

	for _, chainId := range supportedChains {
		l, err := listener.NewListener(chainId, cfg, queue)
		if err != nil {
			log.Fatal(err)
		}

		err = l.Init()
		if err != nil {
			log.Fatal(err)
		}
	}
}
