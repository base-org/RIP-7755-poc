package fetcher

import (
	"context"
	"math/big"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/listener"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/ethereum/go-ethereum/log"
	"github.com/urfave/cli/v2"
	"gopkg.in/yaml.v2"
)

func Main(ctx *cli.Context) error {
	log.SetDefault(log.NewLogger(log.NewTerminalHandlerWithLevel(os.Stderr, log.LevelInfo, true)))

	networksFile, err := os.ReadFile("log-fetcher/config/networks.yaml")
	if err != nil {
		log.Crit("Failed to read networks file", "error", err)
	}

	// expand environment variables
	networksFile = []byte(os.ExpandEnv(string(networksFile)))

	var cfg chains.NetworksConfig
	err = yaml.Unmarshal(networksFile, &cfg)
	if err != nil {
		log.Crit("Failed to unmarshal networks file", "error", err)
	}

	queue, err := store.NewQueue(ctx)
	if err != nil {
		return err
	}
	defer queue.Close()

	var wg sync.WaitGroup
	stopped, stop := context.WithCancel(context.Background())

	for _, chainId := range ctx.StringSlice("supported-chains") {
		chainIdBigInt, ok := new(big.Int).SetString(chainId, 10)
		if !ok {
			log.Crit("Failed to convert chainId to big.Int", "chainId", chainId)
		}

		l, err := listener.NewListener(chainIdBigInt, cfg.Networks, queue)
		if err != nil {
			log.Crit("Failed to create listener", "error", err)
		}

		wg.Add(1)
		err = l.Start()
		if err != nil {
			log.Crit("Failed to start listener", "error", err)
		}

		go func() {
			defer wg.Done()
			<-stopped.Done()
			l.Stop()
		}()
	}

	// Handle signals to initiate shutdown
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	<-c

	log.Info("Shutting down...")
	stop()
	wg.Wait()

	return nil
}
