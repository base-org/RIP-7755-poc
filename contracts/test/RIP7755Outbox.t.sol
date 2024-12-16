// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {CAIP10} from "../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {ERC7786Base} from "../src/ERC7786Base.sol";
import {Call} from "../src/RIP7755Structs.sol";
import {RIP7755Outbox} from "../src/RIP7755Outbox.sol";

import {MockOutbox} from "./mocks/MockOutbox.sol";

contract RIP7755OutboxTest is Test, ERC7786Base {
    using GlobalTypes for address;
    using CAIP10 for address;

    MockOutbox outbox;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");

    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    event MessagePosted(
        bytes32 indexed outboxId, string sender, string receiver, bytes payload, uint256 value, bytes[] attributes
    );
    event CrossChainCallCompleted(bytes32 indexed requestHash, address submitter);
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

    function test_sendMessage_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount / 2, false);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, adjustedAttributes));

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagePosted(messageId, sender, receiver, payload, 0, adjustedAttributes);
        outbox.sendMessage(sender, receiver, payload, attributes);

        adjustedAttributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 2);
        messageId = keccak256(abi.encode(sender, receiver, payload, adjustedAttributes));

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagePosted(messageId, sender, receiver, payload, 0, adjustedAttributes);
        outbox.sendMessage("", receiver, payload, attributes);
    }

    function test_sendMessage_reverts_ifInvalidNativeCurrency(uint256 rewardAmount) external fundAlice(rewardAmount) {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        (, string memory receiver, bytes memory payload, bytes[] memory attributes,) = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, rewardAmount, 0));
        outbox.sendMessage("", receiver, payload, attributes);
    }

    function test_sendMessage_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        (, string memory receiver, bytes memory payload, bytes[] memory attributes,) = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, 0, 1));
        outbox.sendMessage{value: 1}("", receiver, payload, attributes);
    }

    function test_sendMessage_reverts_ifExpiryTooSoon(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory receiver, bytes memory payload, bytes[] memory attributes, bytes[] memory adjustedAttributes) =
            _initMessage(rewardAmount, false);
        (attributes,) = _setDelay(attributes, adjustedAttributes, 10, block.timestamp + 10 - 1);

        vm.prank(ALICE);
        vm.expectRevert(RIP7755Outbox.ExpiryTooSoon.selector);
        outbox.sendMessage("", receiver, payload, attributes);
    }

    function test_sendMessage_setMetadata_erc20Reward(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, false);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, adjustedAttributes));

        vm.prank(ALICE);
        outbox.sendMessage("", receiver, payload, attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, true);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, adjustedAttributes));

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}("", receiver, payload, attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, false);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, adjustedAttributes));

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagePosted(messageId, sender, receiver, payload, 0, adjustedAttributes);
        outbox.sendMessage("", receiver, payload, attributes);
    }

    function test_sendMessage_pullsERC20FromUserIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory receiver, bytes memory payload, bytes[] memory attributes,) = _initMessage(rewardAmount, false);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        outbox.sendMessage("", receiver, payload, attributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_sendMessage_pullsERC20IntoContractIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory receiver, bytes memory payload, bytes[] memory attributes,) = _initMessage(rewardAmount, false);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(ALICE);
        outbox.sendMessage("", receiver, payload, attributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_claimReward_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes,) =
            _initMessage(rewardAmount, false);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.claimReward(sender, receiver, payload, attributes, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestAlreadyCompleted(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);
    }

    function test_claimReward_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (
            bytes32 messageId,
            string memory sender,
            string memory receiver,
            bytes memory payload,
            ,
            bytes[] memory adjustedAttributes
        ) = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallCompleted(messageId, FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);
    }

    function test_claimReward_storesCompletedStatus_pendingState(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        (
            bytes32 messageId,
            string memory sender,
            string memory receiver,
            bytes memory payload,
            ,
            bytes[] memory adjustedAttributes
        ) = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_sendsNativeAssetRewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, true);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}("", receiver, payload, attributes);

        uint256 fillerBalBefore = FILLER.balance;

        vm.prank(FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);

        uint256 fillerBalAfter = FILLER.balance;

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsNativeAssetRewardFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, true);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}("", receiver, payload, attributes);

        uint256 contractBalBefore = address(outbox).balance;

        vm.prank(FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = mockErc20.balanceOf(FILLER);

        vm.prank(FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);

        uint256 fillerBalAfter = mockErc20.balanceOf(FILLER);

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardFromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes,) =
            _initMessage(rewardAmount, false);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.cancelMessage(sender, receiver, payload, attributes);
    }

    function test_cancelMessage_reverts_requestAlreadyCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);
    }

    function test_cancelMessage_reverts_requestAlreadyCompleted(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(sender, receiver, payload, adjustedAttributes, storageProofData, FILLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);
    }

    function test_cancelMessage_reverts_invalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);

        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidCaller.selector, FILLER, ALICE));
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);
    }

    function test_cancelMessage_reverts_requestStillActive(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);
        uint256 cancelDelaySeconds = outbox.CANCEL_DELAY_SECONDS();

        vm.warp(this.extractExpiry(adjustedAttributes) + cancelDelaySeconds - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.CannotCancelRequestBeforeExpiry.selector,
                block.timestamp,
                this.extractExpiry(adjustedAttributes) + cancelDelaySeconds
            )
        );
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);
    }

    function test_cancelMessage_setsStatusAsCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (
            bytes32 messageId,
            string memory sender,
            string memory receiver,
            bytes memory payload,
            ,
            bytes[] memory adjustedAttributes
        ) = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RIP7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelMessage_emitsCanceledEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (
            bytes32 messageId,
            string memory sender,
            string memory receiver,
            bytes memory payload,
            ,
            bytes[] memory adjustedAttributes
        ) = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        vm.expectEmit(true, false, false, false);
        emit CrossChainCallCanceled(messageId);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);
    }

    function test_cancelMessage_returnsNativeCurrencyToRequester(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}("", receiver, payload, attributes);

        uint256 aliceBalBefore = ALICE.balance;

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);

        uint256 aliceBalAfter = ALICE.balance;

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsNativeCurrencyFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}("", receiver, payload, attributes);

        uint256 contractBalBefore = address(outbox).balance;

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_returnsERC20ToRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsERC20FromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        (, string memory sender, string memory receiver, bytes memory payload,, bytes[] memory adjustedAttributes) =
            _submitRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.warp(this.extractExpiry(adjustedAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(sender, receiver, payload, adjustedAttributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function _submitRequest(uint256 rewardAmount)
        private
        returns (bytes32, string memory, string memory, bytes memory, bytes[] memory, bytes[] memory)
    {
        (
            string memory sender,
            string memory receiver,
            bytes memory payload,
            bytes[] memory attributes,
            bytes[] memory adjustedAttributes
        ) = _initMessage(rewardAmount, false);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, adjustedAttributes));

        vm.prank(ALICE);
        outbox.sendMessage(sender, receiver, payload, attributes);

        return (messageId, sender, receiver, payload, attributes, adjustedAttributes);
    }

    function _initMessage(uint256 rewardAmount, bool isNativeAsset)
        private
        view
        returns (string memory, string memory, bytes memory, bytes[] memory, bytes[] memory)
    {
        string memory sender = address(outbox).local();
        string memory receiver = address(outbox).local();
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](2);
        bytes[] memory adjustedAttributes = new bytes[](4);

        if (isNativeAsset) {
            attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, rewardAmount);
            adjustedAttributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, rewardAmount);
        } else {
            attributes[0] =
                abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
            adjustedAttributes[0] =
                abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        }

        adjustedAttributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        adjustedAttributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());

        (attributes, adjustedAttributes) = _setDelay(attributes, adjustedAttributes, 10, block.timestamp + 11);

        return (sender, receiver, payload, attributes, adjustedAttributes);
    }

    function _setDelay(bytes[] memory attributes, bytes[] memory adjustedAttributes, uint256 delay, uint256 expiry)
        private
        pure
        returns (bytes[] memory, bytes[] memory)
    {
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, delay, expiry);
        adjustedAttributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, delay, expiry);

        return (attributes, adjustedAttributes);
    }

    function extractExpiry(bytes[] calldata attributes) public pure returns (uint256) {
        (, uint256 expiry) = abi.decode(attributes[1][4:], (uint256, uint256));
        return expiry;
    }
}
