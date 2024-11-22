// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {DeployArbitrumProver} from "../script/DeployArbitrumProver.s.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {ArbitrumProver} from "../src/provers/ArbitrumProver.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {MockBeaconOracle} from "./mocks/MockBeaconOracle.sol";

contract ArbitrumProverTest is Test {
    using stdJson for string;

    ArbitrumProver prover;
    ERC20Mock mockErc20;
    MockBeaconOracle mockBeaconOracle;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address private constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    string validProof;
    string invalidL1State;
    string invalidConfirmData;
    string invalidBlockHeaders;
    string finalityDelayInProgress;
    uint256 private _REWARD_AMOUNT = 1 ether;
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0x43f1016e17bdb0194ec37b77cf476d255de00011d02616ab831d2e2ce63d9ee2;

    function setUp() external {
        DeployArbitrumProver deployer = new DeployArbitrumProver();
        prover = deployer.run();
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
        string memory finalityDelayInProgressPath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumFinalityDelayInProgress.json");
        validProof = vm.readFile(path);
        invalidL1State = vm.readFile(invalidPath);
        invalidConfirmData = vm.readFile(invalidConfirmDataPath);
        invalidBlockHeaders = vm.readFile(invalidBlockHeadersPath);
        finalityDelayInProgress = vm.readFile(finalityDelayInProgressPath);
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

        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        ArbitrumProver.RIP7755Proof memory proof = _buildProof(finalityDelayInProgress);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.FinalityDelaySecondsInProgress.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, abi.encode(proof));
    }

    function test_reverts_ifInvalidL1State() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        ArbitrumProver.RIP7755Proof memory proof = _buildProof(invalidL1State);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidStateRoot.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, abi.encode(proof));
    }

    function test_reverts_ifInvalidRLPHeaders() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        ArbitrumProver.RIP7755Proof memory proof = _buildProof(invalidBlockHeaders);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidBlockFieldRLP.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, abi.encode(proof));
    }

    function test_reverts_ifInvalidConfirmData() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        ArbitrumProver.RIP7755Proof memory proof = _buildProof(invalidConfirmData);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidConfirmData.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, abi.encode(proof));
    }

    function test_reverts_ifInvalidL2Storage() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        fillInfo.timestamp++;
        ArbitrumProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidL2Storage.selector);
        prover.validateProof(inboxStorageKey, fillInfo, request, abi.encode(proof));
    }

    function test_proveArbitrumSepoliaStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        ArbitrumProver.RIP7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(request);

        vm.prank(FILLER);
        prover.validateProof(inboxStorageKey, fillInfo, request, abi.encode(proof));
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

    function _initRequest(uint256 rewardAmount) private view returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: ALICE,
            calls: calls,
            destinationChainId: 421614, // arbitrum sepolia chain ID
            proverContract: address(prover),
            inboxContract: 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874, // RIP7755Inbox on Arbitrum Sepolia
            l2Oracle: 0xd80810638dbDF9081b72C1B33c65375e807281C8, // Arbitrum Rollup on Sepolia
            l2OracleStorageKey: bytes32(uint256(118)), // Arbitrum Rollup _nodes storage slot
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 1828828574,
            extraData: new bytes[](0)
        });
    }

    function _initFulfillmentInfo() private view returns (RIP7755Inbox.FulfillmentInfo memory) {
        return RIP7755Inbox.FulfillmentInfo({timestamp: 1732234711, filler: FILLER});
    }

    function _deriveStorageKey(CrossChainRequest memory request) private pure returns (bytes memory) {
        bytes32 requestHash = keccak256(abi.encode(request));
        return abi.encode(keccak256(abi.encodePacked(requestHash, _VERIFIER_STORAGE_LOCATION)));
    }
}
