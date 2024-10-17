// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {DeployRIP7755OutboxArbitrumValidator} from "../script/DeployRIP7755SourceArbitrumValidator.s.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RIP7755OutboxArbitrumValidator} from "../src/source/RIP7755SourceArbitrumValidator.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";

contract RIP7755OutboxArbitrumValidatorTest is Test {
    using stdJson for string;

    RIP7755OutboxArbitrumValidator sourceContract;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address private constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    string validProof;
    string invalidL1State;
    string invalidConfirmData;
    string invalidBlockHeaders;
    uint256 private _REWARD_AMOUNT = 1 ether;

    function setUp() external {
        DeployRIP7755OutboxArbitrumValidator deployer = new DeployRIP7755OutboxArbitrumValidator();
        sourceContract = deployer.run();
        mockErc20 = new ERC20Mock();

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/test/data/ArbitrumSepoliaProof.json");
        string memory invalidPath = string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidL1State.json");
        string memory invalidConfirmDataPath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidConfirmData.json");
        string memory invalidBlockHeadersPath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidBlockHeaders.json");
        validProof = vm.readFile(path);
        invalidL1State = vm.readFile(invalidPath);
        invalidConfirmData = vm.readFile(invalidConfirmDataPath);
        invalidBlockHeaders = vm.readFile(invalidBlockHeadersPath);
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(sourceContract), amount);
        _;
    }

    function test_reverts_ifFinalityDelaySecondsStillInProgress() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        request.finalityDelaySeconds = 1 ether;
        request.expiry = 2 ether;

        vm.prank(ALICE);
        sourceContract.requestCrossChainCall(request);

        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProof(validProof);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxArbitrumValidator.FinalityDelaySecondsInProgress.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_reverts_ifInvalidL1State() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProof(invalidL1State);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxArbitrumValidator.InvalidStateRoot.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_reverts_ifInvalidRLPHeaders() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProof(invalidBlockHeaders);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxArbitrumValidator.InvalidBlockFieldRLP.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_reverts_ifInvalidConfirmData() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProof(invalidConfirmData);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxArbitrumValidator.InvalidConfirmData.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_reverts_ifInvalidL2Storage() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        fillInfo.timestamp++;
        bytes memory storageProofData = _buildProof(validProof);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755OutboxArbitrumValidator.InvalidL2Storage.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_proveArbitrumSepoliaStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProof(validProof);

        vm.prank(FILLER);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function _buildProof(string memory json) private pure returns (bytes memory) {
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

        RIP7755OutboxArbitrumValidator.RIP7755Proof memory proofData = RIP7755OutboxArbitrumValidator.RIP7755Proof({
            sendRoot: json.readBytes(".sendRoot"),
            encodedBlockArray: json.readBytes(".encodedBlockArray"),
            stateProofParams: stateProofParams,
            dstL2StateRootProofParams: dstL2StateRootParams,
            dstL2AccountProofParams: dstL2AccountProofParams,
            nodeIndex: uint64(uint256(json.readBytes32(".nodeIndex")))
        });
        return abi.encode(proofData);
    }

    function _submitRequest(uint256 rewardAmount) private returns (CrossChainRequest memory) {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        sourceContract.requestCrossChainCall(request);

        return request;
    }

    function _initRequest(uint256 rewardAmount) private view returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: ALICE,
            calls: calls,
            originationContract: address(sourceContract),
            originChainId: block.chainid,
            destinationChainId: 11155420,
            verifyingContract: 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874, // RIP7755Inbox on Arbitrum Sepolia
            l2Oracle: 0xd80810638dbDF9081b72C1B33c65375e807281C8, // Arbitrum Rollup on Sepolia
            l2OracleStorageKey: bytes32(uint256(118)), // Arbitrum Rollup _nodes storage slot
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 1828828574,
            precheckContract: address(0),
            precheckData: ""
        });
    }

    function _initFulfillmentInfo() private view returns (RIP7755Inbox.FulfillmentInfo memory) {
        return RIP7755Inbox.FulfillmentInfo({timestamp: 1729041967, filler: FILLER});
    }
}
