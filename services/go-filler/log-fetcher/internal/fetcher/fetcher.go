package fetcher

import (
	"context"
	"math/big"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/listener"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/ethereum/go-ethereum/log"
	"github.com/urfave/cli/v2"
)

func Main(ctx *cli.Context) error {
	log.SetDefault(log.NewLogger(log.NewTerminalHandlerWithLevel(os.Stderr, log.LevelInfo, true)))

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

		l, err := listener.NewListener(chainIdBigInt, ctx, queue)
		if err != nil {
			log.Crit("Failed to create listener", "error", err)
		}

		wg.Add(1)
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		err = l.Start(ctx)
		cancel()
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
