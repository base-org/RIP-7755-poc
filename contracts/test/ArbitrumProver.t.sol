// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {BlockHeaders} from "../src/libraries/BlockHeaders.sol";
import {CAIP10} from "../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {ArbitrumProver} from "../src/libraries/provers/ArbitrumProver.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {ERC7786Base} from "../src/ERC7786Base.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {RIP7755OutboxToArbitrum} from "../src/outboxes/RIP7755OutboxToArbitrum.sol";

import {MockArbitrumProver} from "./mocks/MockArbitrumProver.sol";
import {MockBeaconOracle} from "./mocks/MockBeaconOracle.sol";

contract ArbitrumProverTest is Test, ERC7786Base {
    using stdJson for string;
    using GlobalTypes for address;
    using CAIP10 for address;

    MockArbitrumProver prover;
    ERC20Mock mockErc20;
    MockBeaconOracle mockBeaconOracle;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    string validProof;
    string invalidL1State;
    string invalidConfirmData;
    string invalidBlockHeaders;
    string invalidL2Storage;
    uint256 private _REWARD_AMOUNT = 1 ether;
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0x43f1016e17bdb0194ec37b77cf476d255de00011d02616ab831d2e2ce63d9ee2;

    address private constant _INBOX_CONTRACT = 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874;

    function setUp() external {
        prover = new MockArbitrumProver();
        mockErc20 = new ERC20Mock();
        deployCodeTo("MockBeaconOracle.sol", abi.encode(), 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02);
        mockBeaconOracle = MockBeaconOracle(0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02);

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/test/data/ArbitrumSepoliaProof.json");
        string memory invalidPath = string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidL1State.json");
        string memory invalidConfirmDataPath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidConfirmData.json");
        string memory invalidBlockHeadersPath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidBlockHeaders.json");
        string memory invalidL2StoragePath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidL2Storage.json");
        validProof = vm.readFile(path);
        invalidL1State = vm.readFile(invalidPath);
        invalidConfirmData = vm.readFile(invalidConfirmDataPath);
        invalidBlockHeaders = vm.readFile(invalidBlockHeadersPath);
        invalidL2Storage = vm.readFile(invalidL2StoragePath);
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(prover), amount);
        _;
    }

    function test_reverts_ifFinalityDelaySecondsStillInProgress() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, type(uint256).max - 1 ether, 1828828574);

        ArbitrumProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxToArbitrum.FinalityDelaySecondsInProgress.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvalidL1State() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        ArbitrumProver.RIP7755Proof memory proof = _buildProof(invalidL1State);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidStateRoot.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvalidRLPHeaders() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        ArbitrumProver.RIP7755Proof memory proof = _buildProof(invalidBlockHeaders);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(BlockHeaders.InvalidBlockFieldRLP.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvalidConfirmData() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        ArbitrumProver.RIP7755Proof memory proof = _buildProof(invalidConfirmData);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidConfirmData.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvalidL2Storage() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        ArbitrumProver.RIP7755Proof memory proof = _buildProof(invalidL2Storage);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidL2Storage.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_proveArbitrumSepoliaStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        ArbitrumProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function _buildProof(string memory json) private returns (ArbitrumProver.RIP7755Proof memory) {
        StateValidator.StateProofParameters memory stateProofParams = StateValidator.StateProofParameters({
            beaconRoot: json.readBytes32(".stateProofParams.beaconRoot"),
            beaconOracleTimestamp: uint256(json.readBytes32(".stateProofParams.beaconOracleTimestamp")),
            executionStateRoot: json.readBytes32(".stateProofParams.executionStateRoot"),
            stateRootProof: abi.decode(json.parseRaw(".stateProofParams.stateRootProof"), (bytes32[]))
        });
        StateValidator.AccountProofParameters memory dstL2StateRootParams = StateValidator.AccountProofParameters({
            storageKey: json.readBytes(".dstL2StateRootProofParams.storageKey"),
            storageValue: json.readBytes(".dstL2StateRootProofParams.storageValue"),
            accountProof: abi.decode(json.parseRaw(".dstL2StateRootProofParams.accountProof"), (bytes[])),
            storageProof: abi.decode(json.parseRaw(".dstL2StateRootProofParams.storageProof"), (bytes[]))
        });
        StateValidator.AccountProofParameters memory dstL2AccountProofParams = StateValidator.AccountProofParameters({
            storageKey: json.readBytes(".dstL2AccountProofParams.storageKey"),
            storageValue: json.readBytes(".dstL2AccountProofParams.storageValue"),
            accountProof: abi.decode(json.parseRaw(".dstL2AccountProofParams.accountProof"), (bytes[])),
            storageProof: abi.decode(json.parseRaw(".dstL2AccountProofParams.storageProof"), (bytes[]))
        });

        mockBeaconOracle.commitBeaconRoot(1, stateProofParams.beaconOracleTimestamp, stateProofParams.beaconRoot);

        return ArbitrumProver.RIP7755Proof({
            sendRoot: json.readBytes(".sendRoot"),
            encodedBlockArray: json.readBytes(".encodedBlockArray"),
            stateProofParams: stateProofParams,
            dstL2StateRootProofParams: dstL2StateRootParams,
            dstL2AccountProofParams: dstL2AccountProofParams,
            nodeIndex: uint64(json.readUint(".nodeIndex"))
        });
    }

    function _initMessage(uint256 rewardAmount)
        private
        view
        returns (string memory, string memory, bytes memory, bytes[] memory)
    {
        string memory sender = address(this).local();
        string memory receiver = _INBOX_CONTRACT.local(); // RIP7755Inbox on Arbitrum Sepolia // 421614, // arbitrum sepolia chain ID
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](6);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, FILLER);
        attributes[5] =
            abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, 0xd80810638dbDF9081b72C1B33c65375e807281C8); // Arbitrum Rollup on Sepolia

        return (sender, receiver, payload, attributes);
    }

    function _deriveStorageKey(bytes32 messageId) private pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
    }
}
