package main

import (
	"context"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/listener"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/ethereum/go-ethereum/log"
)

func main() {
	log.SetDefault(log.NewLogger(log.NewTerminalHandlerWithLevel(os.Stderr, log.LevelInfo, true)))
	cfg, err := config.NewConfig() // Load env vars
	if err != nil {
		log.Crit("Failed to load config", "error", err)
	}

	queue, err := store.NewQueue(cfg)
	if err != nil {
		log.Crit("Failed to create queue", "error", err)
	}
	defer queue.Close()

	var wg sync.WaitGroup
	stopped, stop := context.WithCancel(context.Background())

	for _, chainId := range cfg.SupportedChains {
		l, err := listener.NewListener(chainId, cfg, queue)
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
}
