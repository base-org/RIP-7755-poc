-include .env

.PHONY: test

ARBITRUM_REQUEST_HASH = 0xd2a7d400b8bf591dfa337aced6d4bab04e979ef9d183c9fc30bc1c6c0ce552aa
OPTIMISM_REQUEST_HASH = 0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5
FULFILLER_ADDRESS = 0x23214A0864FC0014CAb6030267738F01AFfdd547
MOCK_VERIFIER_ADDRESS = 0xdac62f96404AB882F5a61CFCaFb0C470a19FC514

# Default Anvil Keys
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
CHAIN_A_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
CHAIN_B_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

CHAIN_A_URL=http://localhost:8546
CHAIN_B_URL=http://localhost:8547

ARBITRUM_RPC = $(ARBITRUM_SEPOLIA_RPC)
OPTIMISM_RPC = $(OPTIMISM_SEPOLIA_RPC)
BASE_RPC = $(BASE_SEPOLIA_RPC)

SUBMIT_REQUEST_RPC = $(OPTIMISM_RPC)
OP_STACK_RPC = $(BASE_RPC)

test:
	forge fmt
	forge test

coverage:
	forge fmt
	forge coverage

deploy-mock:
	forge create --rpc-url $(ARBITRUM_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier --broadcast -vvvv

read-mock:
	cast call $(MOCK_VERIFIER_ADDRESS) "getFulfillmentInfo(bytes32)(uint96,address)" $(ARBITRUM_REQUEST_HASH) --rpc-url $(ARBITRUM_RPC)

set-mock:
	cast send $(MOCK_VERIFIER_ADDRESS) "storeFulfillmentInfo(bytes32,address)" $(ARBITRUM_REQUEST_HASH) $(FULFILLER_ADDRESS) --rpc-url $(ARBITRUM_RPC) --private-key $(PRIVATE_KEY)

deploy-arbitrum-sepolia:
	forge script script/chains/DeployArbitrum.s.sol:DeployArbitrum --rpc-url $(ARBITRUM_RPC) --broadcast -vvvv

deploy-op-stack:
	PRIVATE_KEY=$(PRIVATE_KEY) forge script script/chains/DeployBase.s.sol:DeployBase --rpc-url $(OP_STACK_RPC) --broadcast -vvvv

submit-request:
	PRIVATE_KEY=$(PRIVATE_KEY) forge script script/actions/SubmitRequest.s.sol:SubmitRequest --rpc-url $(SUBMIT_REQUEST_RPC) --broadcast -vvvv

fulfill-request:
	PRIVATE_KEY=$(PRIVATE_KEY) forge script script/actions/SubmitToInbox.s.sol:SubmitToInbox --rpc-url $(OPTIMISM_RPC) --broadcast -vvvv
