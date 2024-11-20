package listener

import (
	"context"
	"fmt"
	"math/big"
	"sync"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/clients"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/handler"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	logger "github.com/ethereum/go-ethereum/log"
)

type Listener interface {
	Start(ctx context.Context) error
	Stop()
}

type listener struct {
	outbox  *bindings.RIP7755Outbox
	handler handler.Handler
	logs    chan *bindings.RIP7755OutboxCrossChainCallRequested
	stop    chan struct{}
	wg      sync.WaitGroup
}

func NewListener(srcChainId *big.Int, ctx chains.CliContext, queue store.Queue) (Listener, error) {
	srcChain, err := chains.GetChainConfig(srcChainId, ctx)
	if err != nil {
		return nil, err
	}

	h, err := handler.NewHandler(ctx, srcChain, queue)
	if err != nil {
		return nil, err
	}

	contractAddress := srcChain.Contracts.Outbox
	if contractAddress == common.HexToAddress("") {
		return nil, fmt.Errorf("source chain %s missing Outbox contract address", srcChain.ChainId)
	}

	client, err := clients.GetEthClient(srcChain)
	if err != nil {
		return nil, fmt.Errorf("failed to get eth client: %v", err)
	}
	outbox, err := bindings.NewRIP7755Outbox(contractAddress, client)
	if err != nil {
		return nil, fmt.Errorf("failed to create Outbox contract binding: %v", err)
	}

	return &listener{
		outbox:  outbox,
		handler: h,
		logs:    make(chan *bindings.RIP7755OutboxCrossChainCallRequested),
		stop:    make(chan struct{}),
	}, nil
}

func (l *listener) Start(ctx context.Context) error {
	sub, err := l.outbox.WatchCrossChainCallRequested(&bind.WatchOpts{}, l.logs, [][32]byte{})
	if err != nil {
		return fmt.Errorf("failed to subscribe to logs: %v", err)
	}

	logger.Info("Subscribed to logs")

	l.wg.Add(1)
	go l.loop(sub)

	return nil
}

func (l *listener) loop(sub ethereum.Subscription) {
	defer l.wg.Done()
	for {
		select {
		case err := <-sub.Err():
			logger.Info("Subscription error", "error", err)
		case log := <-l.logs:
			logger.Info("Log received!")
			logger.Info("Log Block Number", "blockNumber", log.Raw.BlockNumber)
			logger.Info("Log Index", "index", log.Raw.Index)

			err := l.handler.HandleLog(log)
			if err != nil {
				logger.Error("Error handling log", "error", err)
			}
		case <-l.stop:
			sub.Unsubscribe()
			return
		}
	}
}

func (l *listener) Stop() {
	close(l.stop)
	l.wg.Wait()
}
