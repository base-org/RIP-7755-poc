// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {RIP7755Source} from "../src/RIP7755Source.sol";
import {Call, CrossChainCall} from "../src/RIP7755Structs.sol";
import {RIP7755Verifier} from "../src/RIP7755Verifier.sol";

import {MockSource} from "./mocks/MockSource.sol";

contract RIP7755SourceTest is Test {
    MockSource mockSource;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event CrossChainCallRequested(bytes32 indexed requestHash, RIP7755Source.CrossChainRequest request);
    event CrossChainCallCanceled(bytes32 indexed callHash);

    function setUp() public {
        mockSource = new MockSource();
        mockErc20 = new ERC20Mock();
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(mockSource), amount);
        _;
    }

    function test_requestCrossChainCall_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAmount /= 2;
        bytes32 requestHash = mockSource.hashRequestMemory(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(requestHash, request);
        mockSource.requestCrossChainCall(request);

        request.nonce++;
        requestHash = mockSource.hashRequest(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(requestHash, request);
        mockSource.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_reverts_ifInvalidNativeCurrency(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Source.InvalidValue.selector, rewardAmount, 0));
        mockSource.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Source.InvalidValue.selector, 0, 1));
        mockSource.requestCrossChainCall{value: 1}(request);
    }

    function test_requestCrossChainCall_reverts_ifExpiryTooSoon(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.expiry = block.timestamp + request.finalityDelaySeconds - 1;

        vm.prank(ALICE);
        vm.expectRevert(RIP7755Source.ExpiryTooSoon.selector);
        mockSource.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_setMetadata_erc20Reward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        bytes32 requestHash = mockSource.hashRequest(request);
        RIP7755Source.CrossChainCallStatus status = mockSource.getRequestStatus(requestHash);
        assert(status == RIP7755Source.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockSource.requestCrossChainCall{value: rewardAmount}(request);

        bytes32 requestHash = mockSource.hashRequest(request);
        RIP7755Source.CrossChainCallStatus status = mockSource.getRequestStatus(requestHash);
        assert(status == RIP7755Source.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        bytes32 callHash = mockSource.hashRequest(request);
        CrossChainCall memory call = mockSource.convertToCrossChainCall(request);
        call.nonce++;

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(callHash, request);
        mockSource.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_pullsERC20FromUserIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_requestCrossChainCall_pullsERC20IntoContractIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(mockSource));

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        uint256 contractBalAfter = mockErc20.balanceOf(address(mockSource));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_claimReward_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Source.InvalidStatusForClaim.selector, RIP7755Source.CrossChainCallStatus.None
            )
        );
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestAlreadyCompleted(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Source.InvalidStatusForClaim.selector, RIP7755Source.CrossChainCallStatus.Completed
            )
        );
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestCancelled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockSource.cancelRequest(request);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Source.InvalidStatusForClaim.selector, RIP7755Source.CrossChainCallStatus.Canceled
            )
        );
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_reverts_ifValidationFails(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(false);

        vm.prank(FILLER);
        vm.expectRevert();
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_storesCompletedStatus_pendingState(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);

        bytes32 requestHash = mockSource.hashRequest(request);
        RIP7755Source.CrossChainCallStatus status = mockSource.getRequestStatus(requestHash);
        assert(status == RIP7755Source.CrossChainCallStatus.Completed);
    }

    function test_claimReward_sendsNativeAssetRewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockSource.requestCrossChainCall{value: rewardAmount}(request);

        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = FILLER.balance;

        vm.prank(FILLER);
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 fillerBalAfter = FILLER.balance;

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsNativeAssetRewardFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockSource.requestCrossChainCall{value: rewardAmount}(request);

        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = address(mockSource).balance;

        vm.prank(FILLER);
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 contractBalAfter = address(mockSource).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = mockErc20.balanceOf(FILLER);

        vm.prank(FILLER);
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 fillerBalAfter = mockErc20.balanceOf(FILLER);

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardFromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = mockErc20.balanceOf(address(mockSource));

        vm.prank(FILLER);
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 contractBalAfter = mockErc20.balanceOf(address(mockSource));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelRequest_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Source.InvalidStatusForRequestCancel.selector, RIP7755Source.CrossChainCallStatus.None
            )
        );
        mockSource.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestAlreadyCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockSource.cancelRequest(request);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Source.InvalidStatusForRequestCancel.selector, RIP7755Source.CrossChainCallStatus.Canceled
            )
        );
        mockSource.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestAlreadyCompleted(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Verifier.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        mockSource.claimReward(request, fillInfo, storageProofData, FILLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Source.InvalidStatusForRequestCancel.selector, RIP7755Source.CrossChainCallStatus.Completed
            )
        );
        mockSource.cancelRequest(request);
    }

    function test_cancelRequest_reverts_invalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);

        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Source.InvalidCaller.selector, FILLER, ALICE));
        mockSource.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestStillActive(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS() - 1);
        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Source.CannotCancelRequestBeforeExpiry.selector, block.timestamp, request.expiry
            )
        );
        mockSource.cancelRequest(request);
    }

    function test_cancelRequest_setsStatusAsCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes32 requestHash = mockSource.hashRequest(request);

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockSource.cancelRequest(request);

        RIP7755Source.CrossChainCallStatus status = mockSource.getRequestStatus(requestHash);
        assert(status == RIP7755Source.CrossChainCallStatus.Canceled);
    }

    function test_cancelRequest_emitsCanceledEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes32 requestHash = mockSource.hashRequest(request);

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        vm.expectEmit(true, false, false, false);
        emit CrossChainCallCanceled(requestHash);
        mockSource.cancelRequest(request);
    }

    function test_cancelRequest_returnsNativeCurrencyToRequester(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockSource.requestCrossChainCall{value: rewardAmount}(request);

        uint256 aliceBalBefore = ALICE.balance;

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockSource.cancelRequest(request);

        uint256 aliceBalAfter = ALICE.balance;

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelRequest_returnsNativeCurrencyFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockSource.requestCrossChainCall{value: rewardAmount}(request);

        uint256 contractBalBefore = address(mockSource).balance;

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockSource.cancelRequest(request);

        uint256 contractBalAfter = address(mockSource).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelRequest_returnsERC20ToRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockSource.cancelRequest(request);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelRequest_returnsERC20FromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _submitRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(mockSource));

        vm.warp(request.expiry + mockSource.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockSource.cancelRequest(request);

        uint256 contractBalAfter = mockErc20.balanceOf(address(mockSource));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_convertToCrossChainCall_returnsProperConversion(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        CrossChainCall memory call = mockSource.convertToCrossChainCall(request);
        CrossChainCall memory expected = CrossChainCall({
            calls: request.calls,
            originationContract: address(mockSource),
            originChainId: block.chainid,
            destinationChainId: request.destinationChainId,
            nonce: request.nonce,
            verifyingContract: request.verifyingContract,
            precheckContract: request.precheckContract,
            precheckData: request.precheckData
        });

        assertEq(keccak256(abi.encode(call)), keccak256(abi.encode(expected)));
    }

    function _submitRequest(uint256 rewardAmount) private returns (RIP7755Source.CrossChainRequest memory) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        return request;
    }

    function _initRequest(uint256 rewardAmount) private view returns (RIP7755Source.CrossChainRequest memory) {
        return RIP7755Source.CrossChainRequest({
            requester: ALICE,
            calls: calls,
            destinationChainId: 0,
            verifyingContract: address(0),
            l2Oracle: address(0),
            l2OracleStorageKey: bytes32(0),
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 100,
            precheckContract: address(0),
            precheckData: ""
        });
    }

    function _initFulfillmentInfo() private view returns (RIP7755Verifier.FulfillmentInfo memory) {
        return RIP7755Verifier.FulfillmentInfo({timestamp: 0, filler: FILLER});
    }
}
