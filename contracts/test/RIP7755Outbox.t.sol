// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {RIP7755Outbox} from "../src/source/RIP7755Outbox.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";

import {MockOutbox} from "./mocks/MockOutbox.sol";

contract RIP7755OutboxTest is Test {
    MockOutbox mockOutbox;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event CrossChainCallRequested(bytes32 indexed requestHash, CrossChainRequest request);
    event CrossChainCallCanceled(bytes32 indexed callHash);

    function setUp() public {
        mockOutbox = new MockOutbox();
        mockErc20 = new ERC20Mock();
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(mockOutbox), amount);
        _;
    }

    function test_requestCrossChainCall_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAmount /= 2;
        bytes32 requestHash = mockOutbox.hashRequestMemory(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(requestHash, request);
        mockOutbox.requestCrossChainCall(request);

        request.nonce++;
        requestHash = mockOutbox.hashRequest(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(requestHash, request);
        mockOutbox.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_reverts_ifInvalidNativeCurrency(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, rewardAmount, 0));
        mockOutbox.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, 0, 1));
        mockOutbox.requestCrossChainCall{value: 1}(request);
    }

    function test_requestCrossChainCall_reverts_ifExpiryTooSoon(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.expiry = block.timestamp + request.finalityDelaySeconds - 1;

        vm.prank(ALICE);
        vm.expectRevert(RIP7755Outbox.ExpiryTooSoon.selector);
        mockOutbox.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_setMetadata_erc20Reward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall(request);

        bytes32 requestHash = mockOutbox.hashRequest(request);
        RIP7755Outbox.CrossChainCallStatus status = mockOutbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall{value: rewardAmount}(request);

        bytes32 requestHash = mockOutbox.hashRequest(request);
        RIP7755Outbox.CrossChainCallStatus status = mockOutbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        bytes32 callHash = mockOutbox.hashRequest(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(callHash, request);
        mockOutbox.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_pullsERC20FromUserIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall(request);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_requestCrossChainCall_pullsERC20IntoContractIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(mockOutbox));

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall(request);

        uint256 contractBalAfter = mockErc20.balanceOf(address(mockOutbox));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_claimReward_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.None
            )
        );
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestAlreadyCompleted(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockOutbox.cancelRequest(request);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_reverts_ifValidationFails(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(false);

        vm.prank(FILLER);
        vm.expectRevert();
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);
    }

    function test_claimReward_storesCompletedStatus_pendingState(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);

        bytes32 requestHash = mockOutbox.hashRequest(request);
        RIP7755Outbox.CrossChainCallStatus status = mockOutbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_sendsNativeAssetRewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall{value: rewardAmount}(request);

        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = FILLER.balance;

        vm.prank(FILLER);
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 fillerBalAfter = FILLER.balance;

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsNativeAssetRewardFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall{value: rewardAmount}(request);

        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = address(mockOutbox).balance;

        vm.prank(FILLER);
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 contractBalAfter = address(mockOutbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = mockErc20.balanceOf(FILLER);

        vm.prank(FILLER);
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 fillerBalAfter = mockErc20.balanceOf(FILLER);

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardFromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = mockErc20.balanceOf(address(mockOutbox));

        vm.prank(FILLER);
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);

        uint256 contractBalAfter = mockErc20.balanceOf(address(mockOutbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelRequest_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.None
            )
        );
        mockOutbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestAlreadyCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockOutbox.cancelRequest(request);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        mockOutbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestAlreadyCompleted(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        RIP7755Inbox.FulfillmentInfo memory fillInfo = _initFulfillmentInfo();
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        mockOutbox.claimReward(request, fillInfo, storageProofData, FILLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        mockOutbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_invalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidCaller.selector, FILLER, ALICE));
        mockOutbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestStillActive(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        uint256 cancelDelaySeconds = mockOutbox.CANCEL_DELAY_SECONDS();

        vm.warp(request.expiry + cancelDelaySeconds - 1);
        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.CannotCancelRequestBeforeExpiry.selector,
                block.timestamp,
                request.expiry + cancelDelaySeconds
            )
        );
        mockOutbox.cancelRequest(request);
    }

    function test_cancelRequest_setsStatusAsCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes32 requestHash = mockOutbox.hashRequest(request);

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockOutbox.cancelRequest(request);

        RIP7755Outbox.CrossChainCallStatus status = mockOutbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelRequest_emitsCanceledEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes32 requestHash = mockOutbox.hashRequest(request);

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        vm.expectEmit(true, false, false, false);
        emit CrossChainCallCanceled(requestHash);
        mockOutbox.cancelRequest(request);
    }

    function test_cancelRequest_returnsNativeCurrencyToRequester(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall{value: rewardAmount}(request);

        uint256 aliceBalBefore = ALICE.balance;

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockOutbox.cancelRequest(request);

        uint256 aliceBalAfter = ALICE.balance;

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelRequest_returnsNativeCurrencyFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall{value: rewardAmount}(request);

        uint256 contractBalBefore = address(mockOutbox).balance;

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockOutbox.cancelRequest(request);

        uint256 contractBalAfter = address(mockOutbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelRequest_returnsERC20ToRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockOutbox.cancelRequest(request);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelRequest_returnsERC20FromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(mockOutbox));

        vm.warp(request.expiry + mockOutbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        mockOutbox.cancelRequest(request);

        uint256 contractBalAfter = mockErc20.balanceOf(address(mockOutbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function _submitRequest(uint256 rewardAmount) private returns (CrossChainRequest memory) {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        mockOutbox.requestCrossChainCall(request);

        return request;
    }

    function _initRequest(uint256 rewardAmount) private view returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: ALICE,
            calls: calls,
            originationContract: address(mockOutbox),
            originChainId: block.chainid,
            destinationChainId: 0,
            verifyingContract: address(0),
            l2Oracle: address(0),
            l2OracleStorageKey: bytes32(0),
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: block.timestamp + 11,
            precheckContract: address(0),
            precheckData: ""
        });
    }

    function _initFulfillmentInfo() private view returns (RIP7755Inbox.FulfillmentInfo memory) {
        return RIP7755Inbox.FulfillmentInfo({timestamp: 0, filler: FILLER});
    }
}
