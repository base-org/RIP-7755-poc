package parser

import (
	"fmt"
	"math/big"
	"strings"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/abis"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)

type Parser interface {
	ParseLog(vLog types.Log) (LogCrossChainCallRequested, error)
}

type parser struct {
	outboxAbi abi.ABI
}

func NewParser() (Parser, error) {
	contractAbi, err := abi.JSON(strings.NewReader(abis.RIP7755OutboxAbi))
	if err != nil {
		return nil, err
	}

	return &parser{outboxAbi: contractAbi}, nil
}

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

func (p *parser) ParseLog(vLog types.Log) (LogCrossChainCallRequested, error) {
	fmt.Println("Parsing log")

	var event LogCrossChainCallRequested

	err := p.outboxAbi.UnpackIntoInterface(&event, "CrossChainCallRequested", vLog.Data)
	if err != nil {
		return LogCrossChainCallRequested{}, err
	}

	event.RequestHash = vLog.Topics[1]

	return event, nil
}
