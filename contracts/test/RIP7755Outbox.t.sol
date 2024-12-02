// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {RIP7755Outbox} from "../src/RIP7755Outbox.sol";

import {MockOutbox} from "./mocks/MockOutbox.sol";

contract RIP7755OutboxTest is Test {
    MockOutbox outbox;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event CrossChainCallRequested(bytes32 indexed requestHash, CrossChainRequest request);
    event CrossChainCallCanceled(bytes32 indexed callHash);

    function setUp() public {
        outbox = new MockOutbox();
        mockErc20 = new ERC20Mock();
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(outbox), amount);
        _;
    }

    function test_requestCrossChainCall_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAmount /= 2;
        bytes32 requestHash = outbox.hashRequestMemory(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(requestHash, request);
        outbox.requestCrossChainCall(request);

        request.nonce++;
        requestHash = outbox.hashRequest(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(requestHash, request);
        outbox.requestCrossChainCall(request);
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
        outbox.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, 0, 1));
        outbox.requestCrossChainCall{value: 1}(request);
    }

    function test_requestCrossChainCall_reverts_ifExpiryTooSoon(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.expiry = block.timestamp + request.finalityDelaySeconds - 1;

        vm.prank(ALICE);
        vm.expectRevert(RIP7755Outbox.ExpiryTooSoon.selector);
        outbox.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_setMetadata_erc20Reward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        outbox.requestCrossChainCall(request);

        bytes32 requestHash = outbox.hashRequest(request);
        RIP7755Outbox.CrossChainCallStatus status = outbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        outbox.requestCrossChainCall{value: rewardAmount}(request);

        bytes32 requestHash = outbox.hashRequest(request);
        RIP7755Outbox.CrossChainCallStatus status = outbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        bytes32 callHash = outbox.hashRequest(request);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(callHash, request);
        outbox.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_pullsERC20FromUserIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        outbox.requestCrossChainCall(request);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_requestCrossChainCall_pullsERC20IntoContractIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(ALICE);
        outbox.requestCrossChainCall(request);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_claimReward_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.claimReward(request, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestAlreadyCompleted(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(request, storageProofData, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.claimReward(request, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelRequest(request);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.claimReward(request, storageProofData, FILLER);
    }

    function test_claimReward_storesCompletedStatus_pendingState(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(request, storageProofData, FILLER);

        bytes32 requestHash = outbox.hashRequest(request);
        RIP7755Outbox.CrossChainCallStatus status = outbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_sendsNativeAssetRewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        outbox.requestCrossChainCall{value: rewardAmount}(request);

        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = FILLER.balance;

        vm.prank(FILLER);
        outbox.claimReward(request, storageProofData, FILLER);

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
        outbox.requestCrossChainCall{value: rewardAmount}(request);

        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = address(outbox).balance;

        vm.prank(FILLER);
        outbox.claimReward(request, storageProofData, FILLER);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = mockErc20.balanceOf(FILLER);

        vm.prank(FILLER);
        outbox.claimReward(request, storageProofData, FILLER);

        uint256 fillerBalAfter = mockErc20.balanceOf(FILLER);

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardFromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(FILLER);
        outbox.claimReward(request, storageProofData, FILLER);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

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
        outbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestAlreadyCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelRequest(request);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestAlreadyCompleted(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(request, storageProofData, FILLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_invalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidCaller.selector, FILLER, ALICE));
        outbox.cancelRequest(request);
    }

    function test_cancelRequest_reverts_requestStillActive(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        uint256 cancelDelaySeconds = outbox.CANCEL_DELAY_SECONDS();

        vm.warp(request.expiry + cancelDelaySeconds - 1);
        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.CannotCancelRequestBeforeExpiry.selector,
                block.timestamp,
                request.expiry + cancelDelaySeconds
            )
        );
        outbox.cancelRequest(request);
    }

    function test_cancelRequest_setsStatusAsCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes32 requestHash = outbox.hashRequest(request);

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelRequest(request);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getRequestStatus(requestHash);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelRequest_emitsCanceledEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);
        bytes32 requestHash = outbox.hashRequest(request);

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        vm.expectEmit(true, false, false, false);
        emit CrossChainCallCanceled(requestHash);
        outbox.cancelRequest(request);
    }

    function test_cancelRequest_returnsNativeCurrencyToRequester(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        outbox.requestCrossChainCall{value: rewardAmount}(request);

        uint256 aliceBalBefore = ALICE.balance;

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelRequest(request);

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
        outbox.requestCrossChainCall{value: rewardAmount}(request);

        uint256 contractBalBefore = address(outbox).balance;

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelRequest(request);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelRequest_returnsERC20ToRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelRequest(request);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelRequest_returnsERC20FromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        CrossChainRequest memory request = _submitRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.warp(request.expiry + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelRequest(request);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function _submitRequest(uint256 rewardAmount) private returns (CrossChainRequest memory) {
        CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        outbox.requestCrossChainCall(request);

        return request;
    }

    function _initRequest(uint256 rewardAmount) private view returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: ALICE,
            calls: calls,
            sourceChainId: block.chainid,
            origin: address(outbox),
            destinationChainId: 0,
            inboxContract: address(0),
            l2Oracle: address(0),
            l2OracleStorageKey: bytes32(0),
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: block.timestamp + 11,
            extraData: new bytes[](0)
        });
    }
}
