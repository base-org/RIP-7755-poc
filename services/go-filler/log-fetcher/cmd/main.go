package main

import (
	"context"
	"fmt"
	"log"
	"math/big"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

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

	var wg sync.WaitGroup
	stopped, stop := context.WithCancel(context.Background())

	for _, chainId := range supportedChains {
		l, err := listener.NewListener(chainId, cfg, queue)
		if err != nil {
			log.Fatal(err)
		}

		wg.Add(1)
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		err = l.Start(ctx)
		cancel()
		if err != nil {
			log.Fatal(err)
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

	fmt.Println("Shutting down...")
	stop()
	wg.Wait()
}
