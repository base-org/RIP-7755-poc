// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {CAIP2} from "openzeppelin-contracts/contracts/utils/CAIP2.sol";
import {CAIP10} from "openzeppelin-contracts/contracts/utils/CAIP10.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {RIP7755Outbox} from "../src/RIP7755Outbox.sol";

import {MockOutbox} from "./mocks/MockOutbox.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract RIP7755OutboxTest is BaseTest {
    using GlobalTypes for address;
    using CAIP10 for address;
    using Strings for address;

    struct TestMessage {
        string destinationChain;
        string sender;
        Message[] messages;
        bytes[] attributes;
    }

    MockOutbox outbox;

    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    event MessagesPosted(
        bytes32 indexed outboxId, string destinationChain, string sender, Message[] messages, bytes[] globalAttributes
    );
    event CrossChainCallCompleted(bytes32 indexed requestHash, address submitter);
    event CrossChainCallCanceled(bytes32 indexed callHash);

    function setUp() public {
        _setUp();
        outbox = new MockOutbox();
        approveAddr = address(outbox);
    }

    function test_sendMessage_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        bytes32 messageId = _deriveMessageId(m);

        bytes[] memory adjustedAttributes = _getAdjustedAttributes(m);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagesPosted(messageId, m.destinationChain, m.sender, m.messages, adjustedAttributes);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        adjustedAttributes[3] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 2);
        messageId = outbox.getRequestIdCalldata(m.sender, m.destinationChain, m.messages, adjustedAttributes);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagesPosted(messageId, m.destinationChain, m.sender, m.messages, adjustedAttributes);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        bytes32 messageId = _deriveMessageId(m);

        bytes[] memory adjustedAttributes = _getAdjustedAttributes(m);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagesPosted(messageId, m.destinationChain, m.sender, m.messages, adjustedAttributes);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);

        adjustedAttributes[3] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 2);
        messageId = outbox.getRequestIdCalldata(m.sender, m.destinationChain, m.messages, adjustedAttributes);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagesPosted(messageId, m.destinationChain, m.sender, m.messages, adjustedAttributes);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_reverts_ifInvalidNativeCurrency(uint256 rewardAmount) external fundAlice(rewardAmount) {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, rewardAmount, 0));
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_reverts_ifInvalidNativeCurrency(uint256 rewardAmount) external fundAlice(rewardAmount) {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, rewardAmount, 0));
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingAttributes(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.assume(rewardAmount > 0);
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidAttributeLength.selector, 3, 0));
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, new bytes[](0));
    }

    function test_sendMessages_reverts_ifMissingAttributes(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.assume(rewardAmount > 0);
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidAttributeLength.selector, 3, 0));
        outbox.sendMessages(m.destinationChain, m.messages, new bytes[](0));
    }

    function test_sendMessage_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, 0, 1));
        outbox.sendMessage{value: 1}(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidValue.selector, 0, 1));
        outbox.sendMessages{value: 1}(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_reverts_ifExpiryTooSoon(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _setDelay(m.attributes, 10, block.timestamp + 10 - 1);

        vm.prank(ALICE);
        vm.expectRevert(RIP7755Outbox.ExpiryTooSoon.selector);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_reverts_ifExpiryTooSoon(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _setDelay(m.attributes, 10, block.timestamp + 10 - 1);

        vm.prank(ALICE);
        vm.expectRevert(RIP7755Outbox.ExpiryTooSoon.selector);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_setMetadata_erc20Reward(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessages_setMetadata_erc20Reward(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setMetadata_withOptionalPrecheckAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessages_setMetadata_withOptionalPrecheckAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setMetadata_withOptionalL2OracleAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessages_setMetadata_withOptionalL2OracleAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setMetadata_withOptionalShoyuBashiAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessages_setMetadata_withOptionalShoyuBashiAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_reverts_ifUnsupportedAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _FULFILLER_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.UnsupportedAttribute.selector, _FULFILLER_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_reverts_ifUnsupportedAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _FULFILLER_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.UnsupportedAttribute.selector, _FULFILLER_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingRewardAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_reverts_ifMissingRewardAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingDelayAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_reverts_ifMissingDelayAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingInboxAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.MissingRequiredAttribute.selector, _INBOX_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_reverts_ifMissingInboxAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RIP7755Outbox.MissingRequiredAttribute.selector, _INBOX_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(
            m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes
        );

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessages_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessages{value: rewardAmount}(m.destinationChain, m.messages, m.attributes);

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        bytes32 messageId = _deriveMessageId(m);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagesPosted(messageId, m.destinationChain, m.sender, m.messages, _getAdjustedAttributes(m));
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);
    }

    function test_sendMessages_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        bytes32 messageId = _deriveMessageId(m);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagesPosted(messageId, m.destinationChain, m.sender, m.messages, _getAdjustedAttributes(m));
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);
    }

    function test_sendMessage_pullsERC20FromUserIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_sendMessages_pullsERC20FromUserIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_sendMessage_pullsERC20IntoContractIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_sendMessages_pullsERC20IntoContractIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(ALICE);
        outbox.sendMessages(m.destinationChain, m.messages, m.attributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_claimReward_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.claimReward(m.sender, m.destinationChain, m.messages, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestAlreadyCompleted(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );
    }

    function test_claimReward_reverts_requestCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );
    }

    function test_claimReward_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.expectEmit(true, false, false, true);
        emit CrossChainCallCompleted(_deriveMessageId(m), FILLER);
        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );
    }

    function test_claimReward_storesCompletedStatus_pendingState(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_sendsNativeAssetRewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, true);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(
            m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes
        );

        uint256 fillerBalBefore = FILLER.balance;

        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );

        uint256 fillerBalAfter = FILLER.balance;

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsNativeAssetRewardFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(
            m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes
        );

        uint256 contractBalBefore = address(outbox).balance;

        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = mockErc20.balanceOf(FILLER);

        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );

        uint256 fillerBalAfter = mockErc20.balanceOf(FILLER);

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardFromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, m.attributes);
    }

    function test_cancelMessage_reverts_requestAlreadyCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));
    }

    function test_cancelMessage_reverts_requestAlreadyCompleted(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(
            m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m), storageProofData, FILLER
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.InvalidStatus.selector,
                RIP7755Outbox.CrossChainCallStatus.Requested,
                RIP7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));
    }

    function test_cancelMessage_reverts_invalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidCaller.selector, FILLER, ALICE));
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));
    }

    function test_cancelMessage_reverts_requestStillActive(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        uint256 cancelDelaySeconds = outbox.CANCEL_DELAY_SECONDS();

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + cancelDelaySeconds - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                RIP7755Outbox.CannotCancelRequestBeforeExpiry.selector,
                block.timestamp,
                this.extractExpiry(_getAdjustedAttributes(m)) + cancelDelaySeconds
            )
        );
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));
    }

    function test_cancelMessage_reverts_ifInvalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Outbox.InvalidCaller.selector, FILLER, ALICE));
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));
    }

    function test_cancelMessage_setsStatusAsCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));

        RIP7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RIP7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelMessage_emitsCanceledEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.expectEmit(true, false, false, false);
        emit CrossChainCallCanceled(_deriveMessageId(m));
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));
    }

    function test_cancelMessage_returnsNativeCurrencyToRequester(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(
            m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes
        );

        uint256 aliceBalBefore = ALICE.balance;

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));

        uint256 aliceBalAfter = ALICE.balance;

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsNativeCurrencyFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(
            m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes
        );

        uint256 contractBalBefore = address(outbox).balance;

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_returnsERC20ToRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsERC20FromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.warp(this.extractExpiry(_getAdjustedAttributes(m)) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.sender, m.destinationChain, m.messages, _getAdjustedAttributes(m));

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_supportsAttribute_returnsTrue_ifDelayAttribute() external view {
        bool supportsDelay = outbox.supportsAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        assertTrue(supportsDelay);
    }

    function test_supportsAttribute_returnsTrue_ifRewardAttribute() external view {
        bool supportsReward = outbox.supportsAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        assertTrue(supportsReward);
    }

    function test_getMessageId_returnsSameValue_asGetMessageIdCalldata() external view {
        TestMessage memory m = _initMessage(100, false);
        bytes32 messageId = outbox.getRequestId(m.sender, m.destinationChain, m.messages, m.attributes);
        bytes32 messageIdCalldata = outbox.getRequestIdCalldata(m.sender, m.destinationChain, m.messages, m.attributes);
        assertEq(messageId, messageIdCalldata);
    }

    function _submitRequest(uint256 rewardAmount) private returns (TestMessage memory) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.messages[0].receiver, m.messages[0].payload, m.attributes);

        return m;
    }

    function _initMessage(uint256 rewardAmount, bool isNativeAsset) private view returns (TestMessage memory) {
        string memory destinationChain = CAIP2.local();
        string memory sender = address(outbox).local();
        Message[] memory messages = new Message[](1);
        messages[0] =
            Message({receiver: address(outbox).toChecksumHexString(), payload: "", attributes: new bytes[](0)});
        bytes[] memory attributes = new bytes[](3);

        if (isNativeAsset) {
            attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, rewardAmount);
        } else {
            attributes[0] =
                abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        }

        attributes = _setDelay(attributes, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_INBOX_ATTRIBUTE_SELECTOR, bytes32(0));

        return TestMessage({
            destinationChain: destinationChain,
            sender: sender,
            messages: messages,
            attributes: attributes
        });
    }

    function _setDelay(bytes[] memory attributes, uint256 delay, uint256 expiry)
        private
        pure
        returns (bytes[] memory)
    {
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, delay, expiry);
        return attributes;
    }

    function extractExpiry(bytes[] calldata attributes) public pure returns (uint256) {
        (, uint256 expiry) = abi.decode(attributes[1][4:], (uint256, uint256));
        return expiry;
    }

    function _addAttribute(bytes[] memory attributes, bytes4 selector) private pure returns (bytes[] memory) {
        bytes[] memory newAttributes = new bytes[](attributes.length + 1);
        for (uint256 i = 0; i < attributes.length; i++) {
            newAttributes[i] = attributes[i];
        }
        newAttributes[attributes.length] = abi.encodeWithSelector(selector);
        return newAttributes;
    }

    function _deriveMessageId(TestMessage memory m) private view returns (bytes32) {
        bytes[] memory adjustedAttributes = _getAdjustedAttributes(m);
        return outbox.getRequestIdCalldata(m.sender, m.destinationChain, m.messages, adjustedAttributes);
    }

    function _getAdjustedAttributes(TestMessage memory m) private view returns (bytes[] memory) {
        bytes[] memory adjustedAttributes = new bytes[](m.attributes.length + 2);
        for (uint256 i = 0; i < m.attributes.length; i++) {
            adjustedAttributes[i] = m.attributes[i];
        }
        adjustedAttributes[m.attributes.length] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        adjustedAttributes[m.attributes.length + 1] =
            abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        return adjustedAttributes;
    }
}
