// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package bindings

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// Call is an auto generated low-level Go binding around an user-defined struct.
type Call struct {
	To    common.Address
	Data  []byte
	Value *big.Int
}

// CrossChainRequest is an auto generated low-level Go binding around an user-defined struct.
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

// RIP7755InboxFulfillmentInfo is an auto generated low-level Go binding around an user-defined struct.
type RIP7755InboxFulfillmentInfo struct {
	Timestamp *big.Int
	Filler    common.Address
}

// RIP7755OutboxMetaData contains all meta data concerning the RIP7755Outbox contract.
var RIP7755OutboxMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"CANCEL_DELAY_SECONDS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"cancelRequest\",\"inputs\":[{\"name\":\"request\",\"type\":\"tuple\",\"internalType\":\"structCrossChainRequest\",\"components\":[{\"name\":\"requester\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"calls\",\"type\":\"tuple[]\",\"internalType\":\"structCall[]\",\"components\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"proverContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"destinationChainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"inboxContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2OracleStorageKey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"rewardAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rewardAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalityDelaySeconds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"precheckContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"precheckData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimReward\",\"inputs\":[{\"name\":\"request\",\"type\":\"tuple\",\"internalType\":\"structCrossChainRequest\",\"components\":[{\"name\":\"requester\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"calls\",\"type\":\"tuple[]\",\"internalType\":\"structCall[]\",\"components\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"proverContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"destinationChainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"inboxContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2OracleStorageKey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"rewardAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rewardAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalityDelaySeconds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"precheckContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"precheckData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"fulfillmentInfo\",\"type\":\"tuple\",\"internalType\":\"structRIP7755Inbox.FulfillmentInfo\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint96\",\"internalType\":\"uint96\"},{\"name\":\"filler\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"payTo\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getRequestStatus\",\"inputs\":[{\"name\":\"requestHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumRIP7755Outbox.CrossChainCallStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"hashRequest\",\"inputs\":[{\"name\":\"request\",\"type\":\"tuple\",\"internalType\":\"structCrossChainRequest\",\"components\":[{\"name\":\"requester\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"calls\",\"type\":\"tuple[]\",\"internalType\":\"structCall[]\",\"components\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"proverContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"destinationChainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"inboxContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2OracleStorageKey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"rewardAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rewardAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalityDelaySeconds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"precheckContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"precheckData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"hashRequestMemory\",\"inputs\":[{\"name\":\"request\",\"type\":\"tuple\",\"internalType\":\"structCrossChainRequest\",\"components\":[{\"name\":\"requester\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"calls\",\"type\":\"tuple[]\",\"internalType\":\"structCall[]\",\"components\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"proverContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"destinationChainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"inboxContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2OracleStorageKey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"rewardAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rewardAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalityDelaySeconds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"precheckContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"precheckData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"requestCrossChainCall\",\"inputs\":[{\"name\":\"request\",\"type\":\"tuple\",\"internalType\":\"structCrossChainRequest\",\"components\":[{\"name\":\"requester\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"calls\",\"type\":\"tuple[]\",\"internalType\":\"structCall[]\",\"components\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"proverContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"destinationChainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"inboxContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2OracleStorageKey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"rewardAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rewardAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalityDelaySeconds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"precheckContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"precheckData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"event\",\"name\":\"CrossChainCallCanceled\",\"inputs\":[{\"name\":\"requestHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrossChainCallRequested\",\"inputs\":[{\"name\":\"requestHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"request\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structCrossChainRequest\",\"components\":[{\"name\":\"requester\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"calls\",\"type\":\"tuple[]\",\"internalType\":\"structCall[]\",\"components\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"proverContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"destinationChainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"inboxContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2OracleStorageKey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"rewardAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rewardAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalityDelaySeconds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"precheckContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"precheckData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AddressInsufficientBalance\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"CannotCancelRequestBeforeExpiry\",\"inputs\":[{\"name\":\"currentTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ExpiryTooSoon\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedInnerCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidCaller\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expectedCaller\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"InvalidStatus\",\"inputs\":[{\"name\":\"expected\",\"type\":\"uint8\",\"internalType\":\"enumRIP7755Outbox.CrossChainCallStatus\"},{\"name\":\"actual\",\"type\":\"uint8\",\"internalType\":\"enumRIP7755Outbox.CrossChainCallStatus\"}]},{\"type\":\"error\",\"name\":\"InvalidValue\",\"inputs\":[{\"name\":\"expected\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"received\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ProofValidationFailed\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// RIP7755OutboxABI is the input ABI used to generate the binding from.
// Deprecated: Use RIP7755OutboxMetaData.ABI instead.
var RIP7755OutboxABI = RIP7755OutboxMetaData.ABI

// RIP7755Outbox is an auto generated Go binding around an Ethereum contract.
type RIP7755Outbox struct {
	RIP7755OutboxCaller     // Read-only binding to the contract
	RIP7755OutboxTransactor // Write-only binding to the contract
	RIP7755OutboxFilterer   // Log filterer for contract events
}

// RIP7755OutboxCaller is an auto generated read-only Go binding around an Ethereum contract.
type RIP7755OutboxCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RIP7755OutboxTransactor is an auto generated write-only Go binding around an Ethereum contract.
type RIP7755OutboxTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RIP7755OutboxFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type RIP7755OutboxFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RIP7755OutboxSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type RIP7755OutboxSession struct {
	Contract     *RIP7755Outbox    // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RIP7755OutboxCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type RIP7755OutboxCallerSession struct {
	Contract *RIP7755OutboxCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts        // Call options to use throughout this session
}

// RIP7755OutboxTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type RIP7755OutboxTransactorSession struct {
	Contract     *RIP7755OutboxTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// RIP7755OutboxRaw is an auto generated low-level Go binding around an Ethereum contract.
type RIP7755OutboxRaw struct {
	Contract *RIP7755Outbox // Generic contract binding to access the raw methods on
}

// RIP7755OutboxCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type RIP7755OutboxCallerRaw struct {
	Contract *RIP7755OutboxCaller // Generic read-only contract binding to access the raw methods on
}

// RIP7755OutboxTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type RIP7755OutboxTransactorRaw struct {
	Contract *RIP7755OutboxTransactor // Generic write-only contract binding to access the raw methods on
}

// NewRIP7755Outbox creates a new instance of RIP7755Outbox, bound to a specific deployed contract.
func NewRIP7755Outbox(address common.Address, backend bind.ContractBackend) (*RIP7755Outbox, error) {
	contract, err := bindRIP7755Outbox(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RIP7755Outbox{RIP7755OutboxCaller: RIP7755OutboxCaller{contract: contract}, RIP7755OutboxTransactor: RIP7755OutboxTransactor{contract: contract}, RIP7755OutboxFilterer: RIP7755OutboxFilterer{contract: contract}}, nil
}

// NewRIP7755OutboxCaller creates a new read-only instance of RIP7755Outbox, bound to a specific deployed contract.
func NewRIP7755OutboxCaller(address common.Address, caller bind.ContractCaller) (*RIP7755OutboxCaller, error) {
	contract, err := bindRIP7755Outbox(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &RIP7755OutboxCaller{contract: contract}, nil
}

// NewRIP7755OutboxTransactor creates a new write-only instance of RIP7755Outbox, bound to a specific deployed contract.
func NewRIP7755OutboxTransactor(address common.Address, transactor bind.ContractTransactor) (*RIP7755OutboxTransactor, error) {
	contract, err := bindRIP7755Outbox(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &RIP7755OutboxTransactor{contract: contract}, nil
}

// NewRIP7755OutboxFilterer creates a new log filterer instance of RIP7755Outbox, bound to a specific deployed contract.
func NewRIP7755OutboxFilterer(address common.Address, filterer bind.ContractFilterer) (*RIP7755OutboxFilterer, error) {
	contract, err := bindRIP7755Outbox(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &RIP7755OutboxFilterer{contract: contract}, nil
}

// bindRIP7755Outbox binds a generic wrapper to an already deployed contract.
func bindRIP7755Outbox(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := RIP7755OutboxMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RIP7755Outbox *RIP7755OutboxRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RIP7755Outbox.Contract.RIP7755OutboxCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RIP7755Outbox *RIP7755OutboxRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.RIP7755OutboxTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RIP7755Outbox *RIP7755OutboxRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.RIP7755OutboxTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RIP7755Outbox *RIP7755OutboxCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RIP7755Outbox.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RIP7755Outbox *RIP7755OutboxTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RIP7755Outbox *RIP7755OutboxTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.contract.Transact(opts, method, params...)
}

// CANCELDELAYSECONDS is a free data retrieval call binding the contract method 0xdf130c43.
//
// Solidity: function CANCEL_DELAY_SECONDS() view returns(uint256)
func (_RIP7755Outbox *RIP7755OutboxCaller) CANCELDELAYSECONDS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RIP7755Outbox.contract.Call(opts, &out, "CANCEL_DELAY_SECONDS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CANCELDELAYSECONDS is a free data retrieval call binding the contract method 0xdf130c43.
//
// Solidity: function CANCEL_DELAY_SECONDS() view returns(uint256)
func (_RIP7755Outbox *RIP7755OutboxSession) CANCELDELAYSECONDS() (*big.Int, error) {
	return _RIP7755Outbox.Contract.CANCELDELAYSECONDS(&_RIP7755Outbox.CallOpts)
}

// CANCELDELAYSECONDS is a free data retrieval call binding the contract method 0xdf130c43.
//
// Solidity: function CANCEL_DELAY_SECONDS() view returns(uint256)
func (_RIP7755Outbox *RIP7755OutboxCallerSession) CANCELDELAYSECONDS() (*big.Int, error) {
	return _RIP7755Outbox.Contract.CANCELDELAYSECONDS(&_RIP7755Outbox.CallOpts)
}

// GetRequestStatus is a free data retrieval call binding the contract method 0x45d07664.
//
// Solidity: function getRequestStatus(bytes32 requestHash) view returns(uint8)
func (_RIP7755Outbox *RIP7755OutboxCaller) GetRequestStatus(opts *bind.CallOpts, requestHash [32]byte) (uint8, error) {
	var out []interface{}
	err := _RIP7755Outbox.contract.Call(opts, &out, "getRequestStatus", requestHash)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// GetRequestStatus is a free data retrieval call binding the contract method 0x45d07664.
//
// Solidity: function getRequestStatus(bytes32 requestHash) view returns(uint8)
func (_RIP7755Outbox *RIP7755OutboxSession) GetRequestStatus(requestHash [32]byte) (uint8, error) {
	return _RIP7755Outbox.Contract.GetRequestStatus(&_RIP7755Outbox.CallOpts, requestHash)
}

// GetRequestStatus is a free data retrieval call binding the contract method 0x45d07664.
//
// Solidity: function getRequestStatus(bytes32 requestHash) view returns(uint8)
func (_RIP7755Outbox *RIP7755OutboxCallerSession) GetRequestStatus(requestHash [32]byte) (uint8, error) {
	return _RIP7755Outbox.Contract.GetRequestStatus(&_RIP7755Outbox.CallOpts, requestHash)
}

// HashRequest is a free data retrieval call binding the contract method 0xdd7d3b6a.
//
// Solidity: function hashRequest((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) pure returns(bytes32)
func (_RIP7755Outbox *RIP7755OutboxCaller) HashRequest(opts *bind.CallOpts, request CrossChainRequest) ([32]byte, error) {
	var out []interface{}
	err := _RIP7755Outbox.contract.Call(opts, &out, "hashRequest", request)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// HashRequest is a free data retrieval call binding the contract method 0xdd7d3b6a.
//
// Solidity: function hashRequest((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) pure returns(bytes32)
func (_RIP7755Outbox *RIP7755OutboxSession) HashRequest(request CrossChainRequest) ([32]byte, error) {
	return _RIP7755Outbox.Contract.HashRequest(&_RIP7755Outbox.CallOpts, request)
}

// HashRequest is a free data retrieval call binding the contract method 0xdd7d3b6a.
//
// Solidity: function hashRequest((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) pure returns(bytes32)
func (_RIP7755Outbox *RIP7755OutboxCallerSession) HashRequest(request CrossChainRequest) ([32]byte, error) {
	return _RIP7755Outbox.Contract.HashRequest(&_RIP7755Outbox.CallOpts, request)
}

// HashRequestMemory is a free data retrieval call binding the contract method 0x9110312d.
//
// Solidity: function hashRequestMemory((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) pure returns(bytes32)
func (_RIP7755Outbox *RIP7755OutboxCaller) HashRequestMemory(opts *bind.CallOpts, request CrossChainRequest) ([32]byte, error) {
	var out []interface{}
	err := _RIP7755Outbox.contract.Call(opts, &out, "hashRequestMemory", request)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// HashRequestMemory is a free data retrieval call binding the contract method 0x9110312d.
//
// Solidity: function hashRequestMemory((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) pure returns(bytes32)
func (_RIP7755Outbox *RIP7755OutboxSession) HashRequestMemory(request CrossChainRequest) ([32]byte, error) {
	return _RIP7755Outbox.Contract.HashRequestMemory(&_RIP7755Outbox.CallOpts, request)
}

// HashRequestMemory is a free data retrieval call binding the contract method 0x9110312d.
//
// Solidity: function hashRequestMemory((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) pure returns(bytes32)
func (_RIP7755Outbox *RIP7755OutboxCallerSession) HashRequestMemory(request CrossChainRequest) ([32]byte, error) {
	return _RIP7755Outbox.Contract.HashRequestMemory(&_RIP7755Outbox.CallOpts, request)
}

// CancelRequest is a paid mutator transaction binding the contract method 0xa309a4e2.
//
// Solidity: function cancelRequest((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) returns()
func (_RIP7755Outbox *RIP7755OutboxTransactor) CancelRequest(opts *bind.TransactOpts, request CrossChainRequest) (*types.Transaction, error) {
	return _RIP7755Outbox.contract.Transact(opts, "cancelRequest", request)
}

// CancelRequest is a paid mutator transaction binding the contract method 0xa309a4e2.
//
// Solidity: function cancelRequest((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) returns()
func (_RIP7755Outbox *RIP7755OutboxSession) CancelRequest(request CrossChainRequest) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.CancelRequest(&_RIP7755Outbox.TransactOpts, request)
}

// CancelRequest is a paid mutator transaction binding the contract method 0xa309a4e2.
//
// Solidity: function cancelRequest((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) returns()
func (_RIP7755Outbox *RIP7755OutboxTransactorSession) CancelRequest(request CrossChainRequest) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.CancelRequest(&_RIP7755Outbox.TransactOpts, request)
}

// ClaimReward is a paid mutator transaction binding the contract method 0x2dc6629c.
//
// Solidity: function claimReward((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request, (uint96,address) fulfillmentInfo, bytes proof, address payTo) returns()
func (_RIP7755Outbox *RIP7755OutboxTransactor) ClaimReward(opts *bind.TransactOpts, request CrossChainRequest, fulfillmentInfo RIP7755InboxFulfillmentInfo, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RIP7755Outbox.contract.Transact(opts, "claimReward", request, fulfillmentInfo, proof, payTo)
}

// ClaimReward is a paid mutator transaction binding the contract method 0x2dc6629c.
//
// Solidity: function claimReward((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request, (uint96,address) fulfillmentInfo, bytes proof, address payTo) returns()
func (_RIP7755Outbox *RIP7755OutboxSession) ClaimReward(request CrossChainRequest, fulfillmentInfo RIP7755InboxFulfillmentInfo, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.ClaimReward(&_RIP7755Outbox.TransactOpts, request, fulfillmentInfo, proof, payTo)
}

// ClaimReward is a paid mutator transaction binding the contract method 0x2dc6629c.
//
// Solidity: function claimReward((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request, (uint96,address) fulfillmentInfo, bytes proof, address payTo) returns()
func (_RIP7755Outbox *RIP7755OutboxTransactorSession) ClaimReward(request CrossChainRequest, fulfillmentInfo RIP7755InboxFulfillmentInfo, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.ClaimReward(&_RIP7755Outbox.TransactOpts, request, fulfillmentInfo, proof, payTo)
}

// RequestCrossChainCall is a paid mutator transaction binding the contract method 0xe786188e.
//
// Solidity: function requestCrossChainCall((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) payable returns()
func (_RIP7755Outbox *RIP7755OutboxTransactor) RequestCrossChainCall(opts *bind.TransactOpts, request CrossChainRequest) (*types.Transaction, error) {
	return _RIP7755Outbox.contract.Transact(opts, "requestCrossChainCall", request)
}

// RequestCrossChainCall is a paid mutator transaction binding the contract method 0xe786188e.
//
// Solidity: function requestCrossChainCall((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) payable returns()
func (_RIP7755Outbox *RIP7755OutboxSession) RequestCrossChainCall(request CrossChainRequest) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.RequestCrossChainCall(&_RIP7755Outbox.TransactOpts, request)
}

// RequestCrossChainCall is a paid mutator transaction binding the contract method 0xe786188e.
//
// Solidity: function requestCrossChainCall((address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request) payable returns()
func (_RIP7755Outbox *RIP7755OutboxTransactorSession) RequestCrossChainCall(request CrossChainRequest) (*types.Transaction, error) {
	return _RIP7755Outbox.Contract.RequestCrossChainCall(&_RIP7755Outbox.TransactOpts, request)
}

// RIP7755OutboxCrossChainCallCanceledIterator is returned from FilterCrossChainCallCanceled and is used to iterate over the raw logs and unpacked data for CrossChainCallCanceled events raised by the RIP7755Outbox contract.
type RIP7755OutboxCrossChainCallCanceledIterator struct {
	Event *RIP7755OutboxCrossChainCallCanceled // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RIP7755OutboxCrossChainCallCanceledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RIP7755OutboxCrossChainCallCanceled)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RIP7755OutboxCrossChainCallCanceled)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RIP7755OutboxCrossChainCallCanceledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RIP7755OutboxCrossChainCallCanceledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RIP7755OutboxCrossChainCallCanceled represents a CrossChainCallCanceled event raised by the RIP7755Outbox contract.
type RIP7755OutboxCrossChainCallCanceled struct {
	RequestHash [32]byte
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterCrossChainCallCanceled is a free log retrieval operation binding the contract event 0x1be39b5d9d7a848f6e4636bfaf521d9a6b7a351a73c7d0e945b79ffc7e169346.
//
// Solidity: event CrossChainCallCanceled(bytes32 indexed requestHash)
func (_RIP7755Outbox *RIP7755OutboxFilterer) FilterCrossChainCallCanceled(opts *bind.FilterOpts, requestHash [][32]byte) (*RIP7755OutboxCrossChainCallCanceledIterator, error) {

	var requestHashRule []interface{}
	for _, requestHashItem := range requestHash {
		requestHashRule = append(requestHashRule, requestHashItem)
	}

	logs, sub, err := _RIP7755Outbox.contract.FilterLogs(opts, "CrossChainCallCanceled", requestHashRule)
	if err != nil {
		return nil, err
	}
	return &RIP7755OutboxCrossChainCallCanceledIterator{contract: _RIP7755Outbox.contract, event: "CrossChainCallCanceled", logs: logs, sub: sub}, nil
}

// WatchCrossChainCallCanceled is a free log subscription operation binding the contract event 0x1be39b5d9d7a848f6e4636bfaf521d9a6b7a351a73c7d0e945b79ffc7e169346.
//
// Solidity: event CrossChainCallCanceled(bytes32 indexed requestHash)
func (_RIP7755Outbox *RIP7755OutboxFilterer) WatchCrossChainCallCanceled(opts *bind.WatchOpts, sink chan<- *RIP7755OutboxCrossChainCallCanceled, requestHash [][32]byte) (event.Subscription, error) {

	var requestHashRule []interface{}
	for _, requestHashItem := range requestHash {
		requestHashRule = append(requestHashRule, requestHashItem)
	}

	logs, sub, err := _RIP7755Outbox.contract.WatchLogs(opts, "CrossChainCallCanceled", requestHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RIP7755OutboxCrossChainCallCanceled)
				if err := _RIP7755Outbox.contract.UnpackLog(event, "CrossChainCallCanceled", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCrossChainCallCanceled is a log parse operation binding the contract event 0x1be39b5d9d7a848f6e4636bfaf521d9a6b7a351a73c7d0e945b79ffc7e169346.
//
// Solidity: event CrossChainCallCanceled(bytes32 indexed requestHash)
func (_RIP7755Outbox *RIP7755OutboxFilterer) ParseCrossChainCallCanceled(log types.Log) (*RIP7755OutboxCrossChainCallCanceled, error) {
	event := new(RIP7755OutboxCrossChainCallCanceled)
	if err := _RIP7755Outbox.contract.UnpackLog(event, "CrossChainCallCanceled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RIP7755OutboxCrossChainCallRequestedIterator is returned from FilterCrossChainCallRequested and is used to iterate over the raw logs and unpacked data for CrossChainCallRequested events raised by the RIP7755Outbox contract.
type RIP7755OutboxCrossChainCallRequestedIterator struct {
	Event *RIP7755OutboxCrossChainCallRequested // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RIP7755OutboxCrossChainCallRequestedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RIP7755OutboxCrossChainCallRequested)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RIP7755OutboxCrossChainCallRequested)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RIP7755OutboxCrossChainCallRequestedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RIP7755OutboxCrossChainCallRequestedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RIP7755OutboxCrossChainCallRequested represents a CrossChainCallRequested event raised by the RIP7755Outbox contract.
type RIP7755OutboxCrossChainCallRequested struct {
	RequestHash [32]byte
	Request     CrossChainRequest
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterCrossChainCallRequested is a free log retrieval operation binding the contract event 0x91466a77985019372d6bde6728a808e42b6db50de58526264b5b3716bf7d11de.
//
// Solidity: event CrossChainCallRequested(bytes32 indexed requestHash, (address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request)
func (_RIP7755Outbox *RIP7755OutboxFilterer) FilterCrossChainCallRequested(opts *bind.FilterOpts, requestHash [][32]byte) (*RIP7755OutboxCrossChainCallRequestedIterator, error) {

	var requestHashRule []interface{}
	for _, requestHashItem := range requestHash {
		requestHashRule = append(requestHashRule, requestHashItem)
	}

	logs, sub, err := _RIP7755Outbox.contract.FilterLogs(opts, "CrossChainCallRequested", requestHashRule)
	if err != nil {
		return nil, err
	}
	return &RIP7755OutboxCrossChainCallRequestedIterator{contract: _RIP7755Outbox.contract, event: "CrossChainCallRequested", logs: logs, sub: sub}, nil
}

// WatchCrossChainCallRequested is a free log subscription operation binding the contract event 0x91466a77985019372d6bde6728a808e42b6db50de58526264b5b3716bf7d11de.
//
// Solidity: event CrossChainCallRequested(bytes32 indexed requestHash, (address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request)
func (_RIP7755Outbox *RIP7755OutboxFilterer) WatchCrossChainCallRequested(opts *bind.WatchOpts, sink chan<- *RIP7755OutboxCrossChainCallRequested, requestHash [][32]byte) (event.Subscription, error) {

	var requestHashRule []interface{}
	for _, requestHashItem := range requestHash {
		requestHashRule = append(requestHashRule, requestHashItem)
	}

	logs, sub, err := _RIP7755Outbox.contract.WatchLogs(opts, "CrossChainCallRequested", requestHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RIP7755OutboxCrossChainCallRequested)
				if err := _RIP7755Outbox.contract.UnpackLog(event, "CrossChainCallRequested", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCrossChainCallRequested is a log parse operation binding the contract event 0x91466a77985019372d6bde6728a808e42b6db50de58526264b5b3716bf7d11de.
//
// Solidity: event CrossChainCallRequested(bytes32 indexed requestHash, (address,(address,bytes,uint256)[],address,uint256,address,address,bytes32,address,uint256,uint256,uint256,uint256,address,bytes) request)
func (_RIP7755Outbox *RIP7755OutboxFilterer) ParseCrossChainCallRequested(log types.Log) (*RIP7755OutboxCrossChainCallRequested, error) {
	event := new(RIP7755OutboxCrossChainCallRequested)
	if err := _RIP7755Outbox.contract.UnpackLog(event, "CrossChainCallRequested", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
