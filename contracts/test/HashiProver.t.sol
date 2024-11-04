// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {DeployHashiProver} from "../script/DeployHashiProver.s.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {HashiProver} from "../src/provers/HashiProver.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {MockShoyuBashi} from "./mocks/MockShoyuBashi.sol";

contract HashiProverTest is Test {
    using stdJson for string;

    uint256 public immutable HASHI_DOMAIN_DST_CHAIN_ID = 10200;
    /// @notice must be the number of the rlp-encoded block within HashiProverProof.json
    uint256 public immutable HASHI_BLOCK_NUMBER = 12525666;
    /// @notice must be the hash of the rlp-encoded block within HashiProverProof.json
    bytes32 public immutable HASHI_BLOCK_HEADER_HASH =
        0xade99a7f26ae4067ae493547c4960677964de5bf8ac02f7d0c3fbc6a70e1d1d1;

    HashiProver prover;
    ERC20Mock mockErc20;
    MockShoyuBashi shoyuBashi;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address private constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    string validProof;
    string invalidBlockHeaders;
    uint256 private _REWARD_AMOUNT = 1 ether;
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0x43f1016e17bdb0194ec37b77cf476d255de00011d02616ab831d2e2ce63d9ee2;

    function setUp() external {
        vm.createSelectFork(vm.envString("BASESEPOLIA_JSON_RPC_URL"), 17_180_041);
        shoyuBashi = new MockShoyuBashi();
        DeployHashiProver deployer = new DeployHashiProver();
        prover = deployer.run();
        mockErc20 = new ERC20Mock();

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/test/data/HashiProverProof.json");
        string memory invalidBlockHeadersPath =
            string.concat(rootPath, "/test/data/invalids/HashiProverInvalidBlockHeaders.json");
        validProof = vm.readFile(path);
        invalidBlockHeaders = vm.readFile(invalidBlockHeadersPath);

        shoyuBashi.setHash(HASHI_DOMAIN_DST_CHAIN_ID, HASHI_BLOCK_NUMBER, HASHI_BLOCK_HEADER_HASH);
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
        request.finalityDelaySeconds = 1 ether;
        request.expiry = 2 ether;

        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.FinalityDelaySecondsInProgress.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, storageProofData);
    }

    function test_reverts_ifInvaldBlockHeader() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        fillInfo.timestamp++;
        bytes memory storageProofData = _buildProof(invalidBlockHeaders);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidBlockHeader.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, storageProofData);
    }

    function test_reverts_ifInvalidStorage() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        fillInfo.timestamp++;
        bytes memory storageProofData = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidStorage.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, storageProofData);
    }

    function test_proveGnosisChiadoStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(request);
        vm.prank(FILLER);
        prover.validateProof(inboxStorageKey, fillInfo, request, storageProofData);
    }

    function _buildProof(string memory json) private pure returns (bytes memory) {
        StateValidator.AccountProofParameters memory dstAccountProofParams = StateValidator.AccountProofParameters({
            storageKey: json.readBytes(".dstAccountProofParams.storageKey"),
            storageValue: json.readBytes(".dstAccountProofParams.storageValue"),
            accountProof: abi.decode(json.parseRaw(".dstAccountProofParams.accountProof"), (bytes[])),
            storageProof: abi.decode(json.parseRaw(".dstAccountProofParams.storageProof"), (bytes[]))
        });

        HashiProver.RIP7755Proof memory proofData = HashiProver.RIP7755Proof({
            rlpEncodedBlockHeader: json.readBytes(".rlpEncodedBlockHeader"),
            dstAccountProofParams: dstAccountProofParams
        });
        return abi.encode(proofData);
    }

    function _initRequest(uint256 rewardAmount) private view returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: ALICE,
            calls: calls,
            destinationChainId: 10200, // Gnosis Chiado chain ID
            proverContract: address(prover),
            inboxContract: 0xdA7D9c8C3eBd2F0A790b1AbCFcdA3d309379B4d8, // RIP7755Inbox on Gnosis Chiado
            l2Oracle: address(0), // we don't use any L1 contract
            l2OracleStorageKey: bytes32(0), // same as above
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 1828828574,
            precheckContract: address(0), // In reality, there should be a contract that checks if the ShoyuBashi used is the expected one
            precheckData: abi.encode(shoyuBashi) // ShoyuBashi contract to use on the source chain within HashiProver
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
