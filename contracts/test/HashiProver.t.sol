// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {HashiProver} from "../src/libraries/provers/HashiProver.sol";
import {BlockHeaders} from "../src/libraries/BlockHeaders.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {RIP7755OutboxToHashi} from "../src/outboxes/RIP7755OutboxToHashi.sol";

import {MockShoyuBashi} from "./mocks/MockShoyuBashi.sol";
import {MockHashiProver} from "./mocks/MockHashiProver.sol";

contract HashiProverTest is Test {
    using stdJson for string;
    using GlobalTypes for address;
    using BlockHeaders for bytes;

    uint256 public immutable HASHI_DOMAIN_DST_CHAIN_ID = 111112;

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
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(request);
        request.finalityDelaySeconds = type(uint256).max - 1 ether;

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxToHashi.FinalityDelaySecondsInProgress.selector);
        prover.validateProof(inboxStorageKey, request, abi.encode(proof));
    }

    function test_reverts_ifInvaldBlockHeader() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);

        (, uint256 blockNumber,) = proof.rlpEncodedBlockHeader.extractStateRootBlockNumberAndTimestamp();

        bytes32 wrongBlockHeaderHash = bytes32(uint256(0));
        shoyuBashi.setHash(HASHI_DOMAIN_DST_CHAIN_ID, blockNumber, wrongBlockHeaderHash);

        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidBlockHeader.selector);
        prover.validateProof(inboxStorageKey, request, abi.encode(proof));
    }

    function test_reverts_ifInvalidStorage() external fundAlice(_REWARD_AMOUNT) {
        bytes memory wrongStorageValue = "0x23214a0864fc0014cab6030267738f01affdd547000000000000000067444860";
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        proof.dstAccountProofParams.storageValue = wrongStorageValue;
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidStorage.selector);
        prover.validateProof(inboxStorageKey, request, abi.encode(proof));
    }

    function test_proveGnosisChiadoStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);

        HashiProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        prover.validateProof(inboxStorageKey, request, abi.encode(proof));
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

    function _initRequest(uint256 rewardAmount) private view returns (CrossChainRequest memory) {
        bytes[] memory extraData = new bytes[](2);
        extraData[0] = abi.encode(address(0));
        extraData[1] = abi.encode(shoyuBashi);

        return CrossChainRequest({
            requester: ALICE.addressToBytes32(),
            calls: calls,
            sourceChainId: block.chainid,
            origin: address(this).addressToBytes32(),
            destinationChainId: HASHI_DOMAIN_DST_CHAIN_ID,
            inboxContract: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512.addressToBytes32(), // RIP7755Inbox on Gnosis Chiado
            l2Oracle: address(0).addressToBytes32(), // we don't use any L1 contract
            rewardAsset: address(mockErc20).addressToBytes32(),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 1828828574,
            extraData: extraData
        });
    }

    function _initFulfillmentInfo() private view returns (RIP7755Inbox.FulfillmentInfo memory) {
        return RIP7755Inbox.FulfillmentInfo({timestamp: 1730125190, filler: FILLER});
    }

    function _deriveStorageKey(CrossChainRequest memory request) private pure returns (bytes memory) {
        bytes32 requestHash = keccak256(abi.encode(request));
        return abi.encode(keccak256(abi.encodePacked(requestHash, _VERIFIER_STORAGE_LOCATION)));
    }
}
