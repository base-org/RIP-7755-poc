package listener

import (
	"context"
	"fmt"
	"log"
	"math/big"
	"sync"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/clients"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/handler"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
)

type Listener interface {
	Start(ctx context.Context) error
	Stop()
}

type listener struct {
	srcChain *chains.ChainConfig
	handler  handler.Handler
	query    ethereum.FilterQuery
	logs     chan types.Log
	stop     chan struct{}
	wg       sync.WaitGroup
}

func NewListener(srcChainId *big.Int, cfg *config.Config, queue store.Queue) (Listener, error) {
	srcChain, err := chains.GetChainConfig(srcChainId, cfg.RPCs)
	if err != nil {
		log.Fatal(err)
	}

	h, err := handler.NewHandler(cfg, srcChain, queue)
	if err != nil {
		return nil, err
	}

	contractAddress := srcChain.Contracts.Outbox
	if contractAddress == common.HexToAddress("") {
		return nil, fmt.Errorf("source chain %s missing Outbox contract address", srcChain.ChainId)
	}

	crossChainCallRequestedSig := []byte("CrossChainCallRequested(bytes32,(address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes))")
	crossChainCallRequestedHash := crypto.Keccak256Hash(crossChainCallRequestedSig)

	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
		Topics:    [][]common.Hash{{crossChainCallRequestedHash}},
	}

	return &listener{
		srcChain: srcChain,
		handler:  h,
		query:    query,
		logs:     make(chan types.Log),
		stop:     make(chan struct{}),
	}, nil
}

func (l *listener) Start(ctx context.Context) error {
	client, err := clients.GetEthClient(l.srcChain)
	if err != nil {
		return err
	}

	sub, err := client.SubscribeFilterLogs(ctx, l.query, l.logs)
	if err != nil {
		return err
	}

	defer sub.Unsubscribe()

	fmt.Println("Subscribed to logs")

	l.wg.Add(1)
	go l.loop(sub)

	return nil
}

func (l *listener) loop(sub ethereum.Subscription) {
	defer l.wg.Done()
	for {
		select {
		case err := <-sub.Err():
			fmt.Printf("Subscription error: %v\n", err)
		case vLog := <-l.logs:
			fmt.Println("Log received!")
			fmt.Printf("Log Block Number: %d\n", vLog.BlockNumber)
			fmt.Printf("Log Index: %d\n", vLog.Index)

			err := l.handler.HandleLog(vLog)
			if err != nil {
				fmt.Printf("Error handling log: %v\n", err)
			}
		case <-l.stop:
			return
		}
	}
}

func (l *listener) Stop() {
	close(l.stop)
	l.wg.Wait()
}
