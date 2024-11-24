-include .env

.PHONY: test

ARBITRUM_REQUEST_HASH = 0xc57854ca0b344a5016d560b45dc207f1b32c3afbdbddb004ff574e493d015d0b
OPTIMISM_REQUEST_HASH = 0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5
FULFILLER_ADDRESS = 0x23214A0864FC0014CAb6030267738F01AFfdd547
MOCK_VERIFIER_ADDRESS = 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874

# Default Anvil Keys
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
CHAIN_A_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
CHAIN_B_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

CHAIN_A_URL=http://localhost:8546
CHAIN_B_URL=http://localhost:8547

ARBITRUM_RPC = $(ARBITRUM_SEPOLIA_RPC)
OPTIMISM_RPC = $(CHAIN_B_URL)
BASE_RPC = $(CHAIN_A_URL)

test:
	forge fmt
	forge test

coverage:
	forge fmt
	forge coverage

deploy-mock:
	forge create --rpc-url $(ARBITRUM_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

deploy-mock-opt-sep:
	forge create --rpc-url $(OPTIMISM_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

read-mock:
	cast call $(MOCK_VERIFIER_ADDRESS) "getFulfillmentInfo(bytes32)(uint96,address)" $(ARBITRUM_REQUEST_HASH) --rpc-url $(ARBITRUM_RPC)

set-mock:
	cast send $(MOCK_VERIFIER_ADDRESS) "storeFulfillmentInfo(bytes32,address)" $(ARBITRUM_REQUEST_HASH) $(FULFILLER_ADDRESS) --rpc-url $(ARBITRUM_RPC) --private-key $(PRIVATE_KEY)

read-mock-op:
	cast call $(MOCK_VERIFIER_ADDRESS) "getFulfillmentInfo(bytes32)(uint96,address)" $(OPTIMISM_REQUEST_HASH) --rpc-url $(OPTIMISM_RPC)

set-mock-op:
	cast send $(MOCK_VERIFIER_ADDRESS) "storeFulfillmentInfo(bytes32,address)" $(OPTIMISM_REQUEST_HASH) $(FULFILLER_ADDRESS) --rpc-url $(OPTIMISM_RPC) --private-key $(PRIVATE_KEY)

deploy-arbitrum-sepolia:
	forge script script/chains/DeployArbitrum.s.sol:DeployArbitrum --rpc-url $(ARBITRUM_RPC) --broadcast -vvvv

deploy-optimism-sepolia:
	forge script script/chains/DeployBase.s.sol:DeployBase --rpc-url $(OPTIMISM_RPC) --broadcast -vvvv

deploy-base-sepolia:
	forge script script/chains/DeployBase.s.sol:DeployBase --rpc-url $(BASE_RPC) --private-key $(PRIVATE_KEY) --broadcast -vvvv

verify-arb-sepolia:
	forge verify-contract 0xeE962eD1671F655a806cB22623eEA8A7cCc233bC src/RIP7755Inbox.sol:RIP7755Inbox --rpc-url $(ARBITRUM_RPC) --etherscan-api-key $(ARBISCAN_API_KEY)

verify-base-sepolia:
	forge verify-contract 0xB482b292878FDe64691d028A2237B34e91c7c7ea src/RIP7755Inbox.sol:RIP7755Inbox --rpc-url $(BASE_RPC) --etherscan-api-key $(BASESCAN_API_KEY)

submit-request:
	forge script script/actions/SubmitRequest.s.sol:SubmitRequest --rpc-url $(OPTIMISM_RPC) --broadcast -vvvv

fulfill-request:
	forge script script/actions/SubmitToInbox.s.sol:SubmitToInbox --rpc-url $(OPTIMISM_RPC) --broadcast -vvvv
