package parser

import (
	"math/big"
	"os"
	"path/filepath"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)

type Call struct {
	To    common.Address
	Data  []byte
	Value *big.Int
}

type CrossChainRequest struct {
	Requester            common.Address
	Calls                []Call
	ProverContract       common.Address
	DestinationChainId   *big.Int
	InboxContract        common.Address
	L2Oracle             common.Address
	L2OracleStorageKey   [32]byte
	RewardAsset          common.Address
	RewardAmount         *big.Int
	FinalityDelaySeconds *big.Int
	Nonce                *big.Int
	Expiry               *big.Int
	PrecheckContract     common.Address
	PrecheckData         []byte
}

type LogCrossChainCallRequested struct {
	RequestHash [32]byte
	Request     CrossChainRequest
}

func ParseLog(vLog types.Log) (LogCrossChainCallRequested, error) {
	absPath, err := filepath.Abs("internal/abis/RIP7755Outbox.json")
	if err != nil {
		return LogCrossChainCallRequested{}, err
	}

	outboxAbi, err := os.ReadFile(absPath)
	if err != nil {
		return LogCrossChainCallRequested{}, err
	}

	contractAbi, err := abi.JSON(strings.NewReader(string(outboxAbi)))
	if err != nil {
		return LogCrossChainCallRequested{}, err
	}

	var event LogCrossChainCallRequested

	err = contractAbi.UnpackIntoInterface(&event, "CrossChainCallRequested", vLog.Data)
	if err != nil {
		return LogCrossChainCallRequested{}, err
	}

	event.RequestHash = vLog.Topics[1]

	return event, nil
}
