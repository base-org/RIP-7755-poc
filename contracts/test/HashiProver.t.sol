// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {HashiProver} from "../src/libraries/provers/HashiProver.sol";
import {BlockHeaders} from "../src/libraries/BlockHeaders.sol";
import {CAIP10} from "../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RIP7755OutboxToHashi} from "../src/outboxes/RIP7755OutboxToHashi.sol";
import {ERC7786Base} from "../src/ERC7786Base.sol";
import {Call} from "../src/RIP7755Structs.sol";

import {MockShoyuBashi} from "./mocks/MockShoyuBashi.sol";
import {MockHashiProver} from "./mocks/MockHashiProver.sol";

contract HashiProverTest is Test, ERC7786Base {
    using stdJson for string;
    using GlobalTypes for address;
    using BlockHeaders for bytes;
    using CAIP10 for address;

    uint256 public immutable HASHI_DOMAIN_DST_CHAIN_ID = 111112;
    address private constant _INBOX_CONTRACT = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    MockHashiProver prover;
    ERC20Mock mockErc20;
    MockShoyuBashi shoyuBashi;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    string validProof;
    uint256 private constant _REWARD_AMOUNT = 1 ether;
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0x43f1016e17bdb0194ec37b77cf476d255de00011d02616ab831d2e2ce63d9ee2;

    function setUp() external {
        shoyuBashi = new MockShoyuBashi();
        prover = new MockHashiProver();
        mockErc20 = new ERC20Mock();

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/test/data/HashiProverProof.json");
        validProof = vm.readFile(path);
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

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, type(uint256).max - 1 ether, 1828828574);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxToHashi.FinalityDelaySecondsInProgress.selector);
        prover.validateProof(inboxStorageKey, receiver, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvaldBlockHeader() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));
        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);

        (, uint256 blockNumber,) = proof.rlpEncodedBlockHeader.extractStateRootBlockNumberAndTimestamp();

        bytes32 wrongBlockHeaderHash = bytes32(uint256(0));
        shoyuBashi.setHash(HASHI_DOMAIN_DST_CHAIN_ID, blockNumber, wrongBlockHeaderHash);

        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidBlockHeader.selector);
        prover.validateProof(inboxStorageKey, receiver, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvalidStorage() external fundAlice(_REWARD_AMOUNT) {
        bytes memory wrongStorageValue = "0x23214a0864fc0014cab6030267738f01affdd547000000000000000067444860";
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        proof.dstAccountProofParams.storageValue = wrongStorageValue;
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidStorage.selector);
        prover.validateProof(inboxStorageKey, receiver, attributes, abi.encode(proof));
    }

    function test_proveGnosisChiadoStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        prover.validateProof(inboxStorageKey, receiver, attributes, abi.encode(proof));
    }

    function _buildProof(string memory json) private returns (HashiProver.RIP7755Proof memory) {
        StateValidator.AccountProofParameters memory dstAccountProofParams = StateValidator.AccountProofParameters({
            storageKey: json.readBytes(".dstAccountProofParams.storageKey"),
            storageValue: json.readBytes(".dstAccountProofParams.storageValue"),
            accountProof: abi.decode(json.parseRaw(".dstAccountProofParams.accountProof"), (bytes[])),
            storageProof: abi.decode(json.parseRaw(".dstAccountProofParams.storageProof"), (bytes[]))
        });

        bytes memory rlpEncodedBlockHeader = json.readBytes(".rlpEncodedBlockHeader");
        (, uint256 blockNumber,) = rlpEncodedBlockHeader.extractStateRootBlockNumberAndTimestamp();

        shoyuBashi.setHash(HASHI_DOMAIN_DST_CHAIN_ID, blockNumber, rlpEncodedBlockHeader.toBlockHash());

        return HashiProver.RIP7755Proof({
            rlpEncodedBlockHeader: rlpEncodedBlockHeader,
            dstAccountProofParams: dstAccountProofParams
        });
    }

    function _initMessage(uint256 rewardAmount)
        private
        view
        returns (string memory, string memory, bytes memory, bytes[] memory)
    {
        string memory sender = address(this).local();
        string memory receiver = _INBOX_CONTRACT.remote(HASHI_DOMAIN_DST_CHAIN_ID);
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](6);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, FILLER);
        attributes[5] = abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, address(shoyuBashi).addressToBytes32());

        return (sender, receiver, payload, attributes);
    }

    function _deriveStorageKey(bytes32 messageId) private pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
    }
}
