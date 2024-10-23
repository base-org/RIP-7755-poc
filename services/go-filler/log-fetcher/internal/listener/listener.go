package listener

import (
	"context"
	"fmt"
	"log"
	"math/big"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	ethclient "github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/clients"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/handler"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

func Init(srcChain *chains.ChainConfig, cfg *config.Config) {
	client, err := ethclient.GetClient(srcChain)
	if err != nil {
		log.Fatal(err)
	}

	contractAddress := srcChain.Contracts.Outbox
	if contractAddress == common.HexToAddress("") {
		log.Fatalf("Source chain %s missing Outbox contract address", srcChain.ChainId)
	}

	crossChainCallRequestedSig := []byte("CrossChainCallRequested(bytes32,(address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes))")
	crossChainCallRequestedHash := crypto.Keccak256Hash(crossChainCallRequestedSig)

	query := ethereum.FilterQuery{
		FromBlock: big.NewInt(90542608),
		ToBlock:   big.NewInt(90542608),
		Addresses: []common.Address{contractAddress},
		Topics:    [][]common.Hash{{crossChainCallRequestedHash}},
	}

	logs, err := client.FilterLogs(context.Background(), query)
	if err != nil {
		log.Fatal(err)
	}

	for _, vLog := range logs {
		fmt.Println("Log received!")
		fmt.Printf("Log Block Number: %d\n", vLog.BlockNumber)
		fmt.Printf("Log Index: %d\n", vLog.Index)

		err := handler.HandleLog(vLog, srcChain, cfg)
		if err != nil {
			log.Fatal(err)
		}
	}

	// query := ethereum.FilterQuery{
	// 	Addresses: []common.Address{contractAddress},
	// }

	// logs := make(chan types.Log)

	// sub, err := client.SubscribeFilterLogs(context.Background(), query, logs)
	// if err != nil {
	// 	log.Fatal(err)
	// }

	// for {
	// 	select {
	// 	case err := <-sub.Err():
	// 		log.Fatal(err)
	// 	case vLog := <- logs:
	// 		fmt.Println(vLog) // pointer to event log
	// 	}
	// }
}
