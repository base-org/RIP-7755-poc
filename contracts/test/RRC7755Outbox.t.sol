// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {RRC7755Outbox} from "../src/RRC7755Outbox.sol";
import {RRC7755OutboxToArbitrum} from "../src/outboxes/RRC7755OutboxToArbitrum.sol";
import {RRC7755OutboxToHashi} from "../src/outboxes/RRC7755OutboxToHashi.sol";
import {RRC7755OutboxToOPStack} from "../src/outboxes/RRC7755OutboxToOPStack.sol";

import {MockOutbox} from "./mocks/MockOutbox.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract RRC7755OutboxTest is BaseTest {
    using GlobalTypes for address;
    using GlobalTypes for bytes;

    struct TestMessage {
        bytes32 sourceChain;
        bytes32 destinationChain;
        bytes32 sender;
        bytes32 receiver;
        PackedUserOperation userOp;
        bytes payload;
        bytes[] attributes;
        bytes[] userOpAttributes;
    }

    MockOutbox outbox;
    RRC7755OutboxToArbitrum arbitrumOutbox;
    RRC7755OutboxToHashi hashiOutbox;
    RRC7755OutboxToOPStack opStackOutbox;

    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    event MessagePosted(
        bytes32 indexed outboxId,
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes payload,
        uint256 value,
        bytes[] attributes
    );
    event CrossChainCallCompleted(bytes32 indexed requestHash, address submitter);
    event CrossChainCallCanceled(bytes32 indexed callHash);

    function setUp() public {
        _setUp();
        outbox = new MockOutbox();
        arbitrumOutbox = new RRC7755OutboxToArbitrum();
        hashiOutbox = new RRC7755OutboxToHashi();
        opStackOutbox = new RRC7755OutboxToOPStack();
        approveAddr = address(outbox);
    }

    function test_sendMessage_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        uint256 before = outbox.getNonce(ALICE);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        assertEq(outbox.getNonce(ALICE), before + 1);
    }

    function test_sendMessage_arbitrum_reverts_ifInvalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, ALICE, address(arbitrumOutbox)));
        vm.prank(ALICE);
        arbitrumOutbox.processAttributes(m.attributes, address(0), 0);
    }

    function test_sendMessage_arbitrum_reverts_ifInvalidNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1000);

        vm.expectRevert(RRC7755Outbox.InvalidNonce.selector);
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_arbitrum_reverts_ifInvalidAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(bytes4(0x11111111));

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.UnsupportedAttribute.selector, bytes4(0x11111111)));
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_arbitrum_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        uint256 before = arbitrumOutbox.getNonce(ALICE);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        assertEq(arbitrumOutbox.getNonce(ALICE), before + 1);
    }

    function test_sendMessage_arbitrum_reverts_ifMissingRewardAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_arbitrum_reverts_ifMissingL2OracleAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _L2_ORACLE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_arbitrum_reverts_ifMissingNonceAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _NONCE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_arbitrum_reverts_ifMissingRequesterAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[3] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REQUESTER_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_arbitrum_reverts_ifInvalidRequester(uint256 rewardAmount)
        external
        fundAccount(FILLER, rewardAmount)
    {
        vm.prank(FILLER);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.expectRevert(RRC7755Outbox.InvalidRequester.selector);
        vm.prank(FILLER);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_arbitrum_reverts_ifMissingDelayAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(arbitrumOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifInvalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, ALICE, address(hashiOutbox)));
        vm.prank(ALICE);
        hashiOutbox.processAttributes(m.attributes, address(0), 0);
    }

    function test_sendMessage_hashi_reverts_ifInvalidNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1000);

        vm.expectRevert(RRC7755Outbox.InvalidNonce.selector);
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifInvalidAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(bytes4(0x11111111));

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.UnsupportedAttribute.selector, bytes4(0x11111111)));
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        uint256 before = hashiOutbox.getNonce(ALICE);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);

        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        assertEq(hashiOutbox.getNonce(ALICE), before + 1);
    }

    function test_sendMessage_hashi_reverts_ifMissingRewardAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifMissingShoyuBashiAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _SHOYU_BASHI_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifMissingDestinationChainAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _DESTINATION_CHAIN_SELECTOR)
        );
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifMissingNonceAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _NONCE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifMissingRequesterAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);
        m.attributes[3] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REQUESTER_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifInvalidRequester(uint256 rewardAmount)
        external
        fundAccount(FILLER, rewardAmount)
    {
        vm.prank(FILLER);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);

        vm.expectRevert(RRC7755Outbox.InvalidRequester.selector);
        vm.prank(FILLER);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_hashi_reverts_ifMissingDelayAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(hashiOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _DESTINATION_CHAIN_SELECTOR);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        hashiOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_reverts_ifInvalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, ALICE, address(opStackOutbox)));
        vm.prank(ALICE);
        opStackOutbox.processAttributes(m.attributes, address(0), 0);
    }

    function test_sendMessage_opStack_reverts_ifInvalidNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1000);

        vm.expectRevert(RRC7755Outbox.InvalidNonce.selector);
        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_reverts_ifInvalidAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(bytes4(0x11111111));

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.UnsupportedAttribute.selector, bytes4(0x11111111)));
        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        uint256 before = opStackOutbox.getNonce(ALICE);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        assertEq(opStackOutbox.getNonce(ALICE), before + 1);
    }

    function test_sendMessage_opStack_reverts_ifMissingRewardAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_reverts_ifMissingL2OracleAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _L2_ORACLE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_reverts_ifMissingNonceAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _NONCE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_reverts_ifMissingRequesterAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[3] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REQUESTER_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_reverts_ifInvalidRequester(uint256 rewardAmount)
        external
        fundAccount(FILLER, rewardAmount)
    {
        vm.prank(FILLER);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.expectRevert(RRC7755Outbox.InvalidRequester.selector);
        vm.prank(FILLER);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_opStack_reverts_ifMissingDelayAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.prank(ALICE);
        mockErc20.approve(address(opStackOutbox), rewardAmount);

        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        opStackOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifInvalidNativeCurrency(uint256 rewardAmount) external fundAlice(rewardAmount) {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidValue.selector, rewardAmount, 0));
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidValue.selector, 0, 1));
        outbox.sendMessage{value: 1}(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifExpiryTooSoon(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _setDelay(m.attributes, 10, block.timestamp + 10 - 1);

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.ExpiryTooSoon.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_setMetadata_erc20Reward(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setMetadata_withOptionalPrecheckAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setMetadata_userOp(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initUserOpMessage(rewardAmount);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes32 messageId =
            outbox.getUserOpHash(abi.decode(m.payload, (PackedUserOperation)), m.receiver, m.destinationChain);
        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_reverts_ifUnsupportedAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        bytes4 selector = 0x11111111;
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, selector);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.UnsupportedAttribute.selector, selector));
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingRewardAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingDelayAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifIncorrectNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1000);

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.InvalidNonce.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingNonceAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _NONCE_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifIncorrectRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, FILLER.addressToBytes32());

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.InvalidRequester.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingRequesterAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[3] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REQUESTER_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        bytes32 messageId = _deriveMessageId(m);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagePosted(
            messageId, m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, 0, m.attributes
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_pullsERC20FromUserIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_sendMessage_pullsERC20IntoContractIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_processAttributes_reverts_ifInvalidCaller() external {
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, address(this), address(outbox)));
        outbox.processAttributes(new bytes[](0), address(outbox), 0);
    }

    function test_claimReward_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestAlreadyCompleted(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.expectEmit(true, false, false, true);
        emit CrossChainCallCompleted(_deriveMessageId(m), FILLER);
        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_storesCompletedStatus_pendingState(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_storesCompletedStatus_pendingStateUserOp(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitUserOp(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.userOp, storageProofData, FILLER);

        bytes32 messageId = outbox.getUserOpHash(m.userOp, m.receiver, m.destinationChain);
        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RRC7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_sendsNativeAssetRewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, true);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 fillerBalBefore = FILLER.balance;

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

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
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalBefore = address(outbox).balance;

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = mockErc20.balanceOf(FILLER);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        uint256 fillerBalAfter = mockErc20.balanceOf(FILLER);

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardFromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_requestAlreadyCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_requestAlreadyCompleted(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_invalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, FILLER, ALICE));
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_requestStillActive(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        uint256 cancelDelaySeconds = outbox.CANCEL_DELAY_SECONDS();

        vm.warp(this.extractExpiry(m.attributes) + cancelDelaySeconds - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.CannotCancelRequestBeforeExpiry.selector,
                block.timestamp,
                this.extractExpiry(m.attributes) + cancelDelaySeconds
            )
        );
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_ifInvalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, FILLER, ALICE));
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_setsStatusAsCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelMessage_setsStatusAsCanceled_userOp(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitUserOp(rewardAmount);

        vm.warp(this.extractExpiry(m.userOpAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelUserOp(m.destinationChain, m.receiver, m.userOp);

        bytes32 messageId = outbox.getUserOpHash(m.userOp, m.receiver, m.destinationChain);
        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RRC7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelMessage_emitsCanceledEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.expectEmit(true, false, false, false);
        emit CrossChainCallCanceled(_deriveMessageId(m));
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_returnsNativeCurrencyToRequester(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalBefore = ALICE.balance;

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalAfter = ALICE.balance;

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsNativeCurrencyFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalBefore = address(outbox).balance;

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_returnsERC20ToRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsERC20FromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_supportsAttribute_returnsTrue_ifPrecheckAttribute() external view {
        bool supportsPrecheck = outbox.supportsAttribute(_PRECHECK_ATTRIBUTE_SELECTOR);
        assertTrue(supportsPrecheck);
    }

    function test_arbitrum_supportsAttribute_returnsTrue_ifRewardAttribute() external view {
        bool supportsReward = arbitrumOutbox.supportsAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        assertTrue(supportsReward);
    }

    function test_arbitrum_supportsAttribute_returnsTrue_ifL2OracleAttribute() external view {
        bool supportsL2Oracle = arbitrumOutbox.supportsAttribute(_L2_ORACLE_ATTRIBUTE_SELECTOR);
        assertTrue(supportsL2Oracle);
    }

    function test_arbitrum_supportsAttribute_returnsTrue_ifNonceAttribute() external view {
        bool supportsNonce = arbitrumOutbox.supportsAttribute(_NONCE_ATTRIBUTE_SELECTOR);
        assertTrue(supportsNonce);
    }

    function test_arbitrum_supportsAttribute_returnsTrue_ifRequesterAttribute() external view {
        bool supportsRequester = arbitrumOutbox.supportsAttribute(_REQUESTER_ATTRIBUTE_SELECTOR);
        assertTrue(supportsRequester);
    }

    function test_arbitrum_supportsAttribute_returnsTrue_ifDelayAttribute() external view {
        bool supportsDelay = arbitrumOutbox.supportsAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        assertTrue(supportsDelay);
    }

    function test_arbitrum_supportsAttribute_returnsTrue_ifPrecheckAttribute() external view {
        bool supportsPrecheck = arbitrumOutbox.supportsAttribute(_PRECHECK_ATTRIBUTE_SELECTOR);
        assertTrue(supportsPrecheck);
    }

    function test_hashi_supportsAttribute_returnsTrue_ifRewardAttribute() external view {
        bool supportsReward = hashiOutbox.supportsAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        assertTrue(supportsReward);
    }

    function test_hashi_supportsAttribute_returnsTrue_ifShoyuBashiAttribute() external view {
        bool supportsShoyuBashi = hashiOutbox.supportsAttribute(_SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        assertTrue(supportsShoyuBashi);
    }

    function test_hashi_supportsAttribute_returnsTrue_ifDestinationChainAttribute() external view {
        bool supportsDestinationChain = hashiOutbox.supportsAttribute(_DESTINATION_CHAIN_SELECTOR);
        assertTrue(supportsDestinationChain);
    }

    function test_hashi_supportsAttribute_returnsTrue_ifNonceAttribute() external view {
        bool supportsNonce = hashiOutbox.supportsAttribute(_NONCE_ATTRIBUTE_SELECTOR);
        assertTrue(supportsNonce);
    }

    function test_hashi_supportsAttribute_returnsTrue_ifRequesterAttribute() external view {
        bool supportsRequester = hashiOutbox.supportsAttribute(_REQUESTER_ATTRIBUTE_SELECTOR);
        assertTrue(supportsRequester);
    }

    function test_hashi_supportsAttribute_returnsTrue_ifDelayAttribute() external view {
        bool supportsDelay = hashiOutbox.supportsAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        assertTrue(supportsDelay);
    }

    function test_hashi_supportsAttribute_returnsTrue_ifPrecheckAttribute() external view {
        bool supportsPrecheck = hashiOutbox.supportsAttribute(_PRECHECK_ATTRIBUTE_SELECTOR);
        assertTrue(supportsPrecheck);
    }

    function test_opStack_supportsAttribute_returnsTrue_ifRewardAttribute() external view {
        bool supportsReward = opStackOutbox.supportsAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        assertTrue(supportsReward);
    }

    function test_opStack_supportsAttribute_returnsTrue_ifL2OracleAttribute() external view {
        bool supportsL2Oracle = opStackOutbox.supportsAttribute(_L2_ORACLE_ATTRIBUTE_SELECTOR);
        assertTrue(supportsL2Oracle);
    }

    function test_opStack_supportsAttribute_returnsTrue_ifNonceAttribute() external view {
        bool supportsNonce = opStackOutbox.supportsAttribute(_NONCE_ATTRIBUTE_SELECTOR);
        assertTrue(supportsNonce);
    }

    function test_opStack_supportsAttribute_returnsTrue_ifRequesterAttribute() external view {
        bool supportsRequester = opStackOutbox.supportsAttribute(_REQUESTER_ATTRIBUTE_SELECTOR);
        assertTrue(supportsRequester);
    }

    function test_opStack_supportsAttribute_returnsTrue_ifDelayAttribute() external view {
        bool supportsDelay = opStackOutbox.supportsAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        assertTrue(supportsDelay);
    }

    function test_opStack_supportsAttribute_returnsTrue_ifPrecheckAttribute() external view {
        bool supportsPrecheck = opStackOutbox.supportsAttribute(_PRECHECK_ATTRIBUTE_SELECTOR);
        assertTrue(supportsPrecheck);
    }

    function _submitRequest(uint256 rewardAmount) private returns (TestMessage memory) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        return m;
    }

    function _submitUserOp(uint256 rewardAmount) private returns (TestMessage memory) {
        TestMessage memory m = _initUserOpMessage(rewardAmount);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        return m;
    }

    function _initMessage(uint256 rewardAmount, bool isNativeAsset) private view returns (TestMessage memory) {
        bytes32 destinationChain = bytes32(block.chainid);
        bytes32 sender = address(outbox).addressToBytes32();
        Call[] memory calls = new Call[](1);
        calls[0] = Call({to: address(outbox).addressToBytes32(), data: "", value: 0});
        bytes[] memory attributes = new bytes[](4);

        if (isNativeAsset) {
            attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, rewardAmount);
        } else {
            attributes[0] =
                abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        }

        attributes = _setDelay(attributes, 10, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());

        PackedUserOperation memory userOp;

        return TestMessage({
            sourceChain: bytes32(block.chainid),
            destinationChain: destinationChain,
            sender: sender,
            receiver: sender,
            userOp: userOp,
            payload: abi.encode(calls),
            attributes: attributes,
            userOpAttributes: new bytes[](0)
        });
    }

    function _initUserOpMessage(uint256 rewardAmount) private view returns (TestMessage memory) {
        bytes32 destinationChain = bytes32(block.chainid);
        bytes32 sender = address(outbox).addressToBytes32();
        bytes[] memory attributes = new bytes[](4);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);

        attributes = _setDelay(attributes, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(0),
            nonce: 1,
            initCode: "",
            callData: "",
            accountGasLimits: 0,
            preVerificationGas: 0,
            gasFees: 0,
            paymasterAndData: _encodePaymasterAndData(address(outbox), attributes, ALICE),
            signature: ""
        });

        return TestMessage({
            sourceChain: bytes32(block.chainid),
            destinationChain: destinationChain,
            sender: sender,
            receiver: sender,
            userOp: userOp,
            payload: abi.encode(userOp),
            attributes: new bytes[](0),
            userOpAttributes: attributes
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
        return outbox.getRequestId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function _encodePaymasterAndData(address inbox, bytes[] memory attributes, address ethAddress)
        private
        pure
        returns (bytes memory)
    {
        address precheck = address(0);
        uint256 ethAmount = 0.0001 ether;
        uint128 paymasterVerificationGasLimit = 100000;
        uint128 paymasterPostOpGasLimit = 100000;
        return abi.encodePacked(
            inbox,
            paymasterVerificationGasLimit,
            paymasterPostOpGasLimit,
            abi.encode(ethAddress, ethAmount, precheck, attributes)
        );
    }
}
