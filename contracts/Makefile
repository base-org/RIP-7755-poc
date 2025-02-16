-include .env

# ACCOUNT=mock-account-deployer
ACCOUNT=testnet-admin

ARBITRUM_REQUEST_HASH = 0xd2a7d400b8bf591dfa337aced6d4bab04e979ef9d183c9fc30bc1c6c0ce552aa
FULFILLER_ADDRESS = 0x23214A0864FC0014CAb6030267738F01AFfdd547
MOCK_VERIFIER_ADDRESS = 0xdac62f96404AB882F5a61CFCaFb0C470a19FC514

ARBITRUM_RPC = $(ARBITRUM_SEPOLIA_RPC)
OPTIMISM_RPC = $(OPTIMISM_SEPOLIA_RPC)
BASE_RPC = $(BASE_SEPOLIA_RPC)

.PHONY: install-foundry
install-foundry:
	curl -L https://foundry.paradigm.xyz | bash
	~/.foundry/bin/foundryup

.PHONY: test
test:
	forge fmt
	forge test

.PHONY: coverage
coverage:
	forge fmt
	forge coverage --no-match-contract Deploy

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

.PHONY: userop-base-to-arbitrum
userop-base-to-arbitrum:
	forge script script/submitUserOp/ToArbitrum.s.sol:ToArbitrum --rpc-url $(BASE_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: userop-base-to-optimism
userop-base-to-optimism:
	forge script script/submitUserOp/BaseToOptimism.s.sol:BaseToOptimism --rpc-url $(BASE_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: userop-arbitrum-to-base
userop-arbitrum-to-base:
	DESTINATION_CHAIN_ID=84532 forge script script/submitUserOp/FromArbitrum.s.sol:FromArbitrum --rpc-url $(ARBITRUM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: userop-arbitrum-to-optimism
userop-arbitrum-to-optimism:
	DESTINATION_CHAIN_ID=11155420 forge script script/submitUserOp/FromArbitrum.s.sol:FromArbitrum --rpc-url $(ARBITRUM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: userop-optimism-to-arbitrum
userop-optimism-to-arbitrum:
	forge script script/submitUserOp/ToArbitrum.s.sol:ToArbitrum --rpc-url $(OPTIMISM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: userop-optimism-to-base
userop-optimism-to-base:
	forge script script/submitUserOp/OptimismToBase.s.sol:OptimismToBase --rpc-url $(OPTIMISM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: fulfill-request
fulfill-request:
	forge script script/actions/SubmitToInbox.s.sol:SubmitToInbox --rpc-url $(OPTIMISM_RPC) --account $(ACCOUNT) --broadcast -vvvv

.PHONY: recover-paymaster-funds
recover-paymaster-funds:
	forge script script/RecoverPaymasterFunds.s.sol:RecoverPaymasterFunds --account $(ACCOUNT) --broadcast -vvvv
