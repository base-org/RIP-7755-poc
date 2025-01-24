// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {stdJson} from "forge-std/StdJson.sol";
import {CAIP10} from "openzeppelin-contracts/contracts/utils/CAIP10.sol";

import {HashiProver} from "../src/libraries/provers/HashiProver.sol";
import {BlockHeaders} from "../src/libraries/BlockHeaders.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RIP7755OutboxToHashi} from "../src/outboxes/RIP7755OutboxToHashi.sol";

import {MockShoyuBashi} from "./mocks/MockShoyuBashi.sol";
import {MockHashiProver} from "./mocks/MockHashiProver.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract HashiProverTest is BaseTest {
    using stdJson for string;
    using GlobalTypes for address;
    using BlockHeaders for bytes;
    using CAIP10 for address;

    uint256 public immutable HASHI_DOMAIN_DST_CHAIN_ID = 111112;
    address private constant _INBOX_CONTRACT = 0xdac62f96404AB882F5a61CFCaFb0C470a19FC514;

    MockHashiProver prover;
    MockShoyuBashi shoyuBashi;

    function setUp() external {
        shoyuBashi = new MockShoyuBashi();
        prover = new MockHashiProver();
        approveAddr = address(prover);
        _setUp();

        string memory path = string.concat(rootPath, "/test/data/HashiProverProof.json");
        validProof = vm.readFile(path);
    }

    function test_reverts_ifFinalityDelaySecondsStillInProgress() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory destinationChain, Message[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = prover.getRequestId(sender, destinationChain, calls, attributes);

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, type(uint256).max - 1 ether, 1828828574);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxToHashi.FinalityDelaySecondsInProgress.selector);
        prover.validateProof(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvaldBlockHeader() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory destinationChain, Message[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = prover.getRequestId(sender, destinationChain, calls, attributes);
        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);

        (, uint256 blockNumber,) = proof.rlpEncodedBlockHeader.extractStateRootBlockNumberAndTimestamp();

        bytes32 wrongBlockHeaderHash = bytes32(uint256(0));
        shoyuBashi.setHash(HASHI_DOMAIN_DST_CHAIN_ID, blockNumber, wrongBlockHeaderHash);

        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidBlockHeader.selector);
        prover.validateProof(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_reverts_ifInvalidStorage() external fundAlice(_REWARD_AMOUNT) {
        bytes memory wrongStorageValue = "0x23214a0864fc0014cab6030267738f01affdd547000000000000000067444860";
        (string memory sender, string memory destinationChain, Message[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = prover.getRequestId(sender, destinationChain, calls, attributes);

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        proof.dstAccountProofParams.storageValue = wrongStorageValue;
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidStorage.selector);
        prover.validateProof(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
    }

    function test_proveGnosisChiadoStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        (string memory sender, string memory destinationChain, Message[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = prover.getRequestId(sender, destinationChain, calls, attributes);

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        prover.validateProof(inboxStorageKey, _INBOX_CONTRACT, attributes, abi.encode(proof));
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
        returns (string memory, string memory, Message[] memory, bytes[] memory)
    {
        string memory sender = address(this).local();
        string memory destinationChain = _remote(HASHI_DOMAIN_DST_CHAIN_ID);
        Message[] memory calls = new Message[](0);
        bytes[] memory attributes = new bytes[](7);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, FILLER);
        attributes[5] = abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, address(shoyuBashi).addressToBytes32());
        attributes[6] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, bytes32(HASHI_DOMAIN_DST_CHAIN_ID));

        return (sender, destinationChain, calls, attributes);
    }
}
