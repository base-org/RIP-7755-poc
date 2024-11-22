-include .env

.PHONY: test

ARBITRUM_REQUEST_HASH = 0x8c1fcd779345380579a09056caba99fac6401a2c842b0582a5e3bc76e43a517f
OPTIMISM_REQUEST_HASH = 0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5
FULFILLER_ADDRESS = 0x23214A0864FC0014CAb6030267738F01AFfdd547
MOCK_VERIFIER_ADDRESS = 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874

test:
	forge fmt
	forge test

coverage:
	forge fmt
	forge coverage

deploy-mock:
	forge create --rpc-url $(ARBITRUM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

deploy-mock-opt-sep:
	forge create --rpc-url $(OPTIMISM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY) test/mocks/MockVerifier.sol:MockVerifier

read-mock:
	cast call $(MOCK_VERIFIER_ADDRESS) "getFulfillmentInfo(bytes32)(uint96,address)" $(ARBITRUM_REQUEST_HASH) --rpc-url $(ARBITRUM_SEPOLIA_RPC)

set-mock:
	cast send $(MOCK_VERIFIER_ADDRESS) "storeFulfillmentInfo(bytes32,address)" $(ARBITRUM_REQUEST_HASH) $(FULFILLER_ADDRESS) --rpc-url $(ARBITRUM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY)

read-mock-op:
	cast call $(MOCK_VERIFIER_ADDRESS) "getFulfillmentInfo(bytes32)(uint96,address)" $(OPTIMISM_REQUEST_HASH) --rpc-url $(OPTIMISM_SEPOLIA_RPC)

set-mock-op:
	cast send $(MOCK_VERIFIER_ADDRESS) "storeFulfillmentInfo(bytes32,address)" $(OPTIMISM_REQUEST_HASH) $(FULFILLER_ADDRESS) --rpc-url $(OPTIMISM_SEPOLIA_RPC) --private-key $(PRIVATE_KEY)

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