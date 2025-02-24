// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {RRC7755Outbox} from "../src/RRC7755Outbox.sol";
import {RRC7755OutboxToArbitrum} from "../src/outboxes/RRC7755OutboxToArbitrum.sol";

import {BaseTest} from "./BaseTest.t.sol";

contract ArbitrumOutboxTest is BaseTest {
    using GlobalTypes for address;

    struct TestMessage {
        bytes32 sourceChain;
        bytes32 destinationChain;
        bytes32 sender;
        bytes32 receiver;
        bytes payload;
        bytes[] attributes;
    }

    RRC7755OutboxToArbitrum arbitrumOutbox;

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
        arbitrumOutbox = new RRC7755OutboxToArbitrum();
        approveAddr = address(arbitrumOutbox);
    }

    function test_sendMessage_reverts_ifInvalidCaller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, ALICE, address(arbitrumOutbox)));
        vm.prank(ALICE);
        arbitrumOutbox.processAttributes(m.attributes, address(0), 0);
    }

    function test_sendMessage_reverts_ifInvalidNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1000);

        vm.expectRevert(RRC7755Outbox.InvalidNonce.selector);
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifDuplicateAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755OutboxToArbitrum.DuplicateAttribute.selector, _L2_ORACLE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifInvalidAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(bytes4(0x11111111));

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.UnsupportedAttribute.selector, bytes4(0x11111111)));
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        uint256 before = arbitrumOutbox.getNonce(ALICE);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        assertEq(arbitrumOutbox.getNonce(ALICE), before + 1);
    }

    function test_sendMessage_reverts_ifMissingRewardAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingL2OracleAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _L2_ORACLE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingNonceAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _NONCE_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingRequesterAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[3] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REQUESTER_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifInvalidRequester(uint256 rewardAmount)
        external
        fundAccount(FILLER, rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);

        vm.expectRevert(RRC7755Outbox.InvalidRequester.selector);
        vm.prank(FILLER);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingDelayAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount);
        m.attributes = _addAttribute(m.attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        vm.prank(ALICE);
        arbitrumOutbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_supportsAttribute_returnsTrue_ifRewardAttribute() external view {
        bool supportsReward = arbitrumOutbox.supportsAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        assertTrue(supportsReward);
    }

    function test_supportsAttribute_returnsTrue_ifL2OracleAttribute() external view {
        bool supportsL2Oracle = arbitrumOutbox.supportsAttribute(_L2_ORACLE_ATTRIBUTE_SELECTOR);
        assertTrue(supportsL2Oracle);
    }

    function test_supportsAttribute_returnsTrue_ifNonceAttribute() external view {
        bool supportsNonce = arbitrumOutbox.supportsAttribute(_NONCE_ATTRIBUTE_SELECTOR);
        assertTrue(supportsNonce);
    }

    function test_supportsAttribute_returnsTrue_ifRequesterAttribute() external view {
        bool supportsRequester = arbitrumOutbox.supportsAttribute(_REQUESTER_ATTRIBUTE_SELECTOR);
        assertTrue(supportsRequester);
    }

    function test_supportsAttribute_returnsTrue_ifDelayAttribute() external view {
        bool supportsDelay = arbitrumOutbox.supportsAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        assertTrue(supportsDelay);
    }

    function test_supportsAttribute_returnsTrue_ifPrecheckAttribute() external view {
        bool supportsPrecheck = arbitrumOutbox.supportsAttribute(_PRECHECK_ATTRIBUTE_SELECTOR);
        assertTrue(supportsPrecheck);
    }

    function _initMessage(uint256 rewardAmount) private view returns (TestMessage memory) {
        bytes32 destinationChain = bytes32(block.chainid);
        bytes32 sender = address(arbitrumOutbox).addressToBytes32();
        Call[] memory calls = new Call[](1);
        calls[0] = Call({to: address(arbitrumOutbox).addressToBytes32(), data: "", value: 0});
        bytes[] memory attributes = new bytes[](4);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        attributes = _setDelay(attributes, 10, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());

        return TestMessage({
            sourceChain: bytes32(block.chainid),
            destinationChain: destinationChain,
            sender: sender,
            receiver: sender,
            payload: abi.encode(calls),
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

    function _addAttribute(bytes[] memory attributes, bytes4 selector) private pure returns (bytes[] memory) {
        bytes[] memory newAttributes = new bytes[](attributes.length + 1);
        for (uint256 i = 0; i < attributes.length; i++) {
            newAttributes[i] = attributes[i];
        }
        newAttributes[attributes.length] = abi.encodeWithSelector(selector);
        return newAttributes;
    }
}
