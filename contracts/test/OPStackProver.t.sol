// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {OPStackProver} from "../src/libraries/provers/OPStackProver.sol";
import {CAIP10} from "../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {ERC7786Base} from "../src/ERC7786Base.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {RIP7755OutboxToOPStack} from "../src/outboxes/RIP7755OutboxToOPStack.sol";

import {MockBeaconOracle} from "./mocks/MockBeaconOracle.sol";
import {MockOPStackProver} from "./mocks/MockOPStackProver.sol";

contract RIP7755OutboxOPStackValidatorTest is Test, ERC7786Base {
    using stdJson for string;
    using GlobalTypes for address;
    using CAIP10 for address;

    MockOPStackProver prover;
    ERC20Mock mockErc20;
    MockBeaconOracle mockBeaconOracle;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    string validProof;
    string invalidL1StorageProof;
    string invalidL2StateRootProof;
    string invalidL2StorageProof;
    uint256 private _REWARD_AMOUNT = 1 ether;
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0x43f1016e17bdb0194ec37b77cf476d255de00011d02616ab831d2e2ce63d9ee2;

    address private constant _INBOX_CONTRACT = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    function setUp() external {
        prover = new MockOPStackProver();
        mockErc20 = new ERC20Mock();
        deployCodeTo("MockBeaconOracle.sol", abi.encode(), 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02);
        mockBeaconOracle = MockBeaconOracle(0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02);

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/test/data/OPSepoliaProof.json");
        string memory invalidL1StoragePath = string.concat(rootPath, "/test/data/invalids/OPInvalidL1Storage.json");
        string memory invalidL2StateRootPath = string.concat(rootPath, "/test/data/invalids/OPInvalidL2StateRoot.json");
        string memory invalidL2StoragePath = string.concat(rootPath, "/test/data/invalids/OPInvalidL2Storage.json");
        validProof = vm.readFile(path);
        invalidL1StorageProof = vm.readFile(invalidL1StoragePath);
        invalidL2StateRootProof = vm.readFile(invalidL2StateRootPath);
        invalidL2StorageProof = vm.readFile(invalidL2StoragePath);
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(prover), amount);
        _;
    }

    function test_validate_reverts_ifFinalityDelaySecondsInProgress() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, type(uint256).max - 1 ether, 1735681520);

        bytes memory storageProofData = _buildProofAndEncodeProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxToOPStack.FinalityDelaySecondsInProgress.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function test_validate_reverts_ifBeaconRootCallFails() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        OPStackProver.RIP7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.beaconOracleTimestamp++;
        bytes memory storageProofData = abi.encode(proofData);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert();
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function test_validate_reverts_ifInvalidBeaconRoot() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        OPStackProver.RIP7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.beaconRoot = keccak256("invalidRoot");
        bytes memory storageProofData = abi.encode(proofData);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert();
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function test_validate_reverts_ifInvalidL1StateRoot() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        OPStackProver.RIP7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.executionStateRoot = keccak256("invalidRoot");
        bytes memory storageProofData = abi.encode(proofData);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert();
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function test_validate_reverts_ifInvalidL1Storage() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL1StorageProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(OPStackProver.InvalidL1Storage.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function test_validate_reverts_ifInvalidL2StateRoot() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL2StateRootProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(OPStackProver.InvalidL2StateRoot.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function test_validate_reverts_ifInvalidL2Storage() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL2StorageProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(OPStackProver.InvalidL2Storage.selector);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function test_validate_proveOptimismSepoliaStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        bytes memory storageProofData = _buildProofAndEncodeProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        prover.validateProof2(inboxStorageKey, _INBOX_CONTRACT, attributes, storageProofData);
    }

    function _buildProofAndEncodeProof(string memory json) private returns (bytes memory) {
        OPStackProver.RIP7755Proof memory proofData = _buildProof(json);
        return abi.encode(proofData);
    }

    function _buildProof(string memory json) private returns (OPStackProver.RIP7755Proof memory) {
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

        return OPStackProver.RIP7755Proof({
            l2MessagePasserStorageRoot: json.readBytes32(".l2MessagePasserStorageRoot"),
            encodedBlockArray: json.readBytes(".encodedBlockArray"),
            stateProofParams: stateProofParams,
            dstL2StateRootProofParams: dstL2StateRootParams,
            dstL2AccountProofParams: dstL2AccountProofParams
        });
    }

    function _initMessage(uint256 rewardAmount)
        private
        view
        returns (string memory, string memory, bytes memory, bytes[] memory)
    {
        string memory sender = 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874.remote(11155420);
        string memory receiver = _INBOX_CONTRACT.remote(111112);
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](6);

        attributes[0] = abi.encodeWithSelector(
            _REWARD_ATTRIBUTE_SELECTOR, 0x2e234DAe75C793f67A35089C9d99245E1C58470b.addressToBytes32(), rewardAmount
        );
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1735681520);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(
            _REQUESTER_ATTRIBUTE_SELECTOR, 0x328809Bc894f92807417D2dAD6b7C998c1aFdac6.addressToBytes32()
        );
        attributes[4] = abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, FILLER);
        attributes[5] =
            abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        return (sender, receiver, payload, attributes);
    }

    function _deriveStorageKey(bytes32 messageId) private pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
    }
}
