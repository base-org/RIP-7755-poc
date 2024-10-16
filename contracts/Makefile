-include .env

.PHONY: test

test:
	forge fmt
	forge test --fork-url https://sepolia.base.org --fork-block-number 16671909

coverage:
	forge fmt
	forge coverage --fork-url https://sepolia.base.org --fork-block-number 16671909

deploy-mock:
	forge create --rpc-url $(ARBITRUM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

deploy-mock-opt-sep:
	forge create --rpc-url $(OPTIMISM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

read-mock:
	cast call 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "getFulfillmentInfo(bytes32)(uint96,address)" 0x30afd8ae26fc42a6908eab6bafc617694d2c4a25a93ecafe0df925106f592137 --rpc-url $(ARBITRUM_SEPOLIA_RPC)

set-mock:
	cast send 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "storeFulfillmentInfo(bytes32,address)" 0x30afd8ae26fc42a6908eab6bafc617694d2c4a25a93ecafe0df925106f592137 0x23214A0864FC0014CAb6030267738F01AFfdd547 --rpc-url $(ARBITRUM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY)

read-mock-op:
	cast call 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "getFulfillmentInfo(bytes32)(uint96,address)" 0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5 --rpc-url $(OPTIMISM_SEPOLIA_RPC)

set-mock-op:
	cast send 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874 "storeFulfillmentInfo(bytes32,address)" 0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5 0x23214A0864FC0014CAb6030267738F01AFfdd547 --rpc-url $(OPTIMISM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY)
