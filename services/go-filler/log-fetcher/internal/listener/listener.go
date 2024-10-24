package listener

import (
	"context"
	"fmt"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/clients"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/handler"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
)

func Init(srcChain *chains.ChainConfig, cfg *config.Config) error {
	client, err := clients.GetEthClient(srcChain)
	if err != nil {
		return err
	}

	contractAddress := srcChain.Contracts.Outbox
	if contractAddress == common.HexToAddress("") {
		return fmt.Errorf("source chain %s missing Outbox contract address", srcChain.ChainId)
	}

	crossChainCallRequestedSig := []byte("CrossChainCallRequested(bytes32,(address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes))")
	crossChainCallRequestedHash := crypto.Keccak256Hash(crossChainCallRequestedSig)

	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
		Topics:    [][]common.Hash{{crossChainCallRequestedHash}},
	}

	logs := make(chan types.Log)

	sub, err := client.SubscribeFilterLogs(context.Background(), query, logs)
	if err != nil {
		return err
	}

	defer sub.Unsubscribe()

	fmt.Println("Subscribed to logs")

	for {
		select {
		case err := <-sub.Err():
			return err
		case vLog := <-logs:
			fmt.Println("Log received!")
			fmt.Printf("Log Block Number: %d\n", vLog.BlockNumber)
			fmt.Printf("Log Index: %d\n", vLog.Index)

			err := handler.HandleLog(vLog, srcChain, cfg)
			if err != nil {
				return err
			}
		}
	}
}
