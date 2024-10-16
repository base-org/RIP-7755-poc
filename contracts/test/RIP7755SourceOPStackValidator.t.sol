// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {DeployRIP7755SourceBaseValidator} from "../script/DeployRIP7755SourceBaseValidator.s.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RIP7755SourceOPStackValidator} from "../src/source/RIP7755SourceOPStackValidator.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {RIP7755Verifier} from "../src/RIP7755Verifier.sol";

contract RIP7755SourceOPStackValidatorTest is Test {
    using stdJson for string;

    RIP7755SourceOPStackValidator sourceContract;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    string validProof;
    string invalidL1StorageProof;
    string invalidL2StateRootProof;
    string invalidL2StorageProof;
    uint256 private _REWARD_AMOUNT = 1 ether;

    function setUp() external {
        DeployRIP7755SourceBaseValidator deployer = new DeployRIP7755SourceBaseValidator();
        sourceContract = deployer.run();
        mockErc20 = new ERC20Mock();

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
        mockErc20.approve(address(sourceContract), amount);
        _;
    }

    function test_validate_reverts_ifFinalityDelaySecondsInProgress() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _initRequest(_REWARD_AMOUNT);
        request.finalityDelaySeconds = 1 ether;
        request.expiry = 2 ether;

        vm.prank(ALICE);
        sourceContract.requestCrossChainCall(request);

        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProofAndEncodeProof(validProof);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755SourceOPStackValidator.FinalityDelaySecondsInProgress.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_validate_reverts_ifBeaconRootCallFails() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        RIP7755SourceOPStackValidator.RIP7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.beaconOracleTimestamp++;
        bytes memory storageProofData = abi.encode(proofData);

        vm.prank(FILLER);
        vm.expectRevert();
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_validate_reverts_ifInvalidBeaconRoot() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        RIP7755SourceOPStackValidator.RIP7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.beaconRoot = keccak256("invalidRoot");
        bytes memory storageProofData = abi.encode(proofData);

        vm.prank(FILLER);
        vm.expectRevert();
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_validate_reverts_ifInvalidL1StateRoot() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        RIP7755SourceOPStackValidator.RIP7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.executionStateRoot = keccak256("invalidRoot");
        bytes memory storageProofData = abi.encode(proofData);

        vm.prank(FILLER);
        vm.expectRevert();
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_validate_reverts_ifInvalidL1Storage() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL1StorageProof);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755SourceOPStackValidator.InvalidL1Storage.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_validate_reverts_ifInvalidL2StateRoot() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL2StateRootProof);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755SourceOPStackValidator.InvalidL2StateRoot.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_validate_reverts_ifInvalidL2Storage() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL2StorageProof);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755SourceOPStackValidator.InvalidL2Storage.selector);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_validate_proveOptimismSepoliaStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        CrossChainRequest memory request = _submitRequest(_REWARD_AMOUNT);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = _buildProofAndEncodeProof(validProof);

        vm.prank(FILLER);
        sourceContract.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function _buildProofAndEncodeProof(string memory json) private pure returns (bytes memory) {
        RIP7755SourceOPStackValidator.RIP7755Proof memory proofData = _buildProof(json);
        return abi.encode(proofData);
    }

    function _buildProof(string memory json) private pure returns (RIP7755SourceOPStackValidator.RIP7755Proof memory) {
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

        return RIP7755SourceOPStackValidator.RIP7755Proof({
            l2StateRoot: json.readBytes32(".l2StateRoot"),
            l2MessagePasserStorageRoot: json.readBytes32(".l2MessagePasserStorageRoot"),
            l2BlockHash: json.readBytes32(".l2BlockHash"),
            stateProofParams: stateProofParams,
            dstL2StateRootProofParams: dstL2StateRootParams,
            dstL2AccountProofParams: dstL2AccountProofParams
        });
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
            verifyingContract: 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874, // RIP7755Verifier on Optimism Sepolia
            l2Oracle: 0x218CD9489199F321E1177b56385d333c5B598629, // Anchor State Registry on Sepolia
            l2OracleStorageKey: 0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49, // Anchor State Registry storage slot
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 1828828574,
            precheckContract: address(0),
            precheckData: ""
        });
    }

    function _initFulfillmentInfo() private view returns (RIP7755Verifier.FulfillmentInfo memory) {
        return RIP7755Verifier.FulfillmentInfo({timestamp: 1728949124, filler: FILLER});
    }
}
