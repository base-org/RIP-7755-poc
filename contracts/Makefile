-include .env

# ACCOUNT=mock-account-deployer
ACCOUNT=testnet-admin

ARBITRUM_REQUEST_HASH = 0xd2a7d400b8bf591dfa337aced6d4bab04e979ef9d183c9fc30bc1c6c0ce552aa
FULFILLER_ADDRESS = 0x23214A0864FC0014CAb6030267738F01AFfdd547
MOCK_VERIFIER_ADDRESS = 0xdac62f96404AB882F5a61CFCaFb0C470a19FC514
MOCK_ACCOUNT = 0x2c4d5B2d8B7ba9e15F09Da8fD455E312bF774Eeb

CHAIN_A_URL=http://localhost:8546
CHAIN_B_URL=http://localhost:8547

ARBITRUM_RPC = $(ARBITRUM_SEPOLIA_RPC)
OPTIMISM_RPC = $(OPTIMISM_SEPOLIA_RPC)
BASE_RPC = $(BASE_SEPOLIA_RPC)

OP_STACK_RPC = $(BASE_RPC)

.PHONY: test
test:
	forge fmt
	forge test

.PHONY: coverage
coverage:
	forge fmt
	forge coverage

.PHONY: deploy-mock
deploy-mock:
	forge create --rpc-url $(ARBITRUM_RPC) --account $(ACCOUNT) test/mocks/MockVerifier.sol:MockVerifier --broadcast -vvvv

.PHONY: deploy-mock-account
deploy-mock-account:
	forge create --rpc-url $(ARBITRUM_RPC) --account $(ACCOUNT) test/mocks/MockAccount.sol:MockAccount --broadcast -vvvv
	forge create --rpc-url $(OPTIMISM_RPC) --account $(ACCOUNT) test/mocks/MockAccount.sol:MockAccount --broadcast -vvvv
	forge create --rpc-url $(BASE_RPC) --account $(ACCOUNT) test/mocks/MockAccount.sol:MockAccount --broadcast -vvvv

.PHONY: read-mock
read-mock:
	cast call $(MOCK_VERIFIER_ADDRESS) "getFulfillmentInfo(bytes32)(uint96,address)" $(ARBITRUM_REQUEST_HASH) --rpc-url $(ARBITRUM_RPC)

.PHONY: set-mock
set-mock:
	cast send $(MOCK_VERIFIER_ADDRESS) "storeFulfillmentInfo(bytes32,address)" $(ARBITRUM_REQUEST_HASH) $(FULFILLER_ADDRESS) --rpc-url $(ARBITRUM_RPC) --account $(ACCOUNT)

.PHONY: deploy
deploy:
	forge script script/Deploy.s.sol:Deploy --account $(ACCOUNT) --broadcast -vvvv

.PHONY: submit-base-to-arbitrum
submit-base-to-arbitrum:
	forge script script/submitRequest/ToArbitrum.s.sol:ToArbitrum --rpc-url $(BASE_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: submit-base-to-optimism
submit-base-to-optimism:
	forge script script/submitRequest/BaseToOptimism.s.sol:BaseToOptimism --rpc-url $(BASE_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: submit-arbitrum-to-base
submit-arbitrum-to-base:
	DESTINATION_CHAIN_ID=84532 forge script script/submitRequest/FromArbitrum.s.sol:FromArbitrum --rpc-url $(ARBITRUM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: submit-arbitrum-to-optimism
submit-arbitrum-to-optimism:
	DESTINATION_CHAIN_ID=11155420 forge script script/submitRequest/FromArbitrum.s.sol:FromArbitrum --rpc-url $(ARBITRUM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: submit-optimism-to-arbitrum
submit-optimism-to-arbitrum:
	forge script script/submitRequest/ToArbitrum.s.sol:ToArbitrum --rpc-url $(OPTIMISM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: submit-optimism-to-base
submit-optimism-to-base:
	forge script script/submitRequest/OptimismToBase.s.sol:OptimismToBase --rpc-url $(OPTIMISM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: fulfill-request
fulfill-request:
	forge script script/actions/SubmitToInbox.s.sol:SubmitToInbox --rpc-url $(OPTIMISM_RPC) --account $(ACCOUNT) --broadcast -vvvv
