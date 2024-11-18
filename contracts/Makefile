-include .env

.PHONY: test

test:
	forge fmt
	forge test --fork-url https://sepolia.base.org --fork-block-number 18069987

coverage:
	forge fmt
	forge coverage --fork-url https://sepolia.base.org --fork-block-number 18069987

deploy-mock:
	forge create --rpc-url $(ARBITRUM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

deploy-mock-opt-sep:
	forge create --rpc-url $(OPTIMISM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

read-mock:
	cast call 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "getFulfillmentInfo(bytes32)(uint96,address)" 0x2ac60f23d7c0dea48c6b0383f3f3c4453a0983beb90d45cbee51ba52a4b4b0f9 --rpc-url $(ARBITRUM_SEPOLIA_RPC)

read-mock-storage:
	cast storage 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 0xe69a609b2162dcc5af9e0ea127f045c52010347ed0594d871a19290c515ae3cc --rpc-url $(ARBITRUM_SEPOLIA_RPC)

set-mock:
	cast send 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "storeFulfillmentInfo(bytes32,address)" 0x2ac60f23d7c0dea48c6b0383f3f3c4453a0983beb90d45cbee51ba52a4b4b0f9 0x23214A0864FC0014CAb6030267738F01AFfdd547 --rpc-url $(ARBITRUM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY)

read-mock-op:
	cast call 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "getFulfillmentInfo(bytes32)(uint96,address)" 0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5 --rpc-url $(OPTIMISM_SEPOLIA_RPC)

set-mock-op:
	cast send 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "storeFulfillmentInfo(bytes32,address)" 0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5 0x23214A0864FC0014CAb6030267738F01AFfdd547 --rpc-url $(OPTIMISM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY)

deploy-arbitrum-sepolia:
	forge script script/chains/DeployArbitrum.s.sol:DeployArbitrum --rpc-url $(ARBITRUM_SEPOLIA_RPC) --broadcast --verify --etherscan-api-key $(ARBISCAN_API_KEY) -vvvv

deploy-base-sepolia:
	forge script script/chains/DeployBase.s.sol:DeployBase --rpc-url $(BASE_SEPOLIA_RPC) --broadcast --verify --etherscan-api-key $(BASESCAN_API_KEY) -vvvv

verify-arb-sepolia:
	forge verify-contract 0xeE962eD1671F655a806cB22623eEA8A7cCc233bC src/RIP7755Inbox.sol:RIP7755Inbox --rpc-url $(ARBITRUM_SEPOLIA_RPC) --etherscan-api-key $(ARBISCAN_API_KEY)

verify-base-sepolia:
	forge verify-contract 0xB482b292878FDe64691d028A2237B34e91c7c7ea src/RIP7755Inbox.sol:RIP7755Inbox --rpc-url $(BASE_SEPOLIA_RPC) --etherscan-api-key $(BASESCAN_API_KEY)

submit-request:
	forge script script/actions/SubmitRequest.s.sol:SubmitRequest --rpc-url $(ARBITRUM_SEPOLIA_RPC) --broadcast -vvvv