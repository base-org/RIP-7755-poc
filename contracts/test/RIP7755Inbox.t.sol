// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {CAIP2} from "openzeppelin-contracts/contracts/utils/CAIP2.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";

import {MockPrecheck} from "./mocks/MockPrecheck.sol";
import {MockTarget} from "./mocks/MockTarget.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract RIP7755InboxTest is BaseTest {
    using GlobalTypes for address;
    using Strings for address;

    struct TestMessage {
        bytes32 messageId;
        string sourceChain;
        string sender;
        Message[] messages;
        bytes[] attributes;
    }

    RIP7755Inbox inbox;
    MockPrecheck precheck;
    MockTarget target;
    EntryPoint entryPoint;

    event PaymasterDeployed(address indexed sender, address indexed paymaster);
    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    function setUp() public {
        entryPoint = new EntryPoint();
        inbox = new RIP7755Inbox(address(entryPoint));
        precheck = new MockPrecheck();
        target = new MockTarget();
        approveAddr = address(inbox);
        _setUp();
    }

    function test_deployment_reverts_zeroAddress() external {
        vm.expectRevert(RIP7755Inbox.ZeroAddress.selector);
        new RIP7755Inbox(address(0));
    }

    function test_deployPaymaster_deploysPaymaster() external {
        address paymaster = inbox.deployPaymaster(0);
        assertTrue(paymaster != address(0));
    }

    function test_deployPaymaster_fundsEntryPoint(uint128 amount) external fundAccount(FILLER, amount) {
        vm.prank(FILLER);
        inbox.deployPaymaster{value: amount}(amount);

        assertEq(address(entryPoint).balance, amount);
    }

    function test_deployPaymaster_emitsEvent() external {
        vm.expectEmit(true, false, false, false);
        emit PaymasterDeployed(FILLER, address(0));
        vm.prank(FILLER);
        inbox.deployPaymaster(0);
    }

    function test_executeMessages_reverts_userOp() external {
        TestMessage memory m = _initMessage(false, true);

        vm.expectRevert(RIP7755Inbox.UserOp.selector);
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);
    }

    function test_executeMessages_storesFulfillment_withSuccessfulPrecheck() external {
        TestMessage memory m = _initMessage(true, false);

        vm.prank(FILLER);
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessages_reverts_failedPrecheck() external {
        TestMessage memory m = _initMessage(true, false);

        vm.expectRevert();
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);
    }

    function test_executeMessages_reverts_callAlreadyFulfilled() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755Inbox.CallAlreadyFulfilled.selector);
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);
    }

    function test_executeMessages_callsTargetContract(uint256 inputNum) external {
        TestMessage memory m = _initMessage(false, false);

        _appendMessage(
            m,
            Message({
                receiver: address(target).toChecksumHexString(),
                payload: abi.encodeWithSelector(target.target.selector, inputNum),
                attributes: new bytes[](0)
            })
        );

        vm.prank(FILLER);
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);

        assertEq(target.number(), inputNum);
    }

    function test_executeMessages_sendsEth(uint256 amount) external {
        TestMessage memory m = _initMessage(false, false);

        bytes[] memory attributes = new bytes[](1);
        attributes[0] = abi.encodeWithSelector(_VALUE_ATTRIBUTE_SELECTOR, amount);

        _appendMessage(m, Message({receiver: ALICE.toChecksumHexString(), payload: "", attributes: attributes}));

        vm.deal(FILLER, amount);
        vm.prank(FILLER);
        inbox.executeMessages{value: amount}(m.sourceChain, m.sender, m.messages, m.attributes);

        assertEq(ALICE.balance, amount);
    }

    function test_executeMessages_reverts_ifTargetContractReverts() external {
        TestMessage memory m = _initMessage(false, false);

        _appendMessage(
            m,
            Message({
                receiver: address(target).toChecksumHexString(),
                payload: abi.encodeWithSelector(target.shouldFail.selector),
                attributes: new bytes[](0)
            })
        );

        vm.prank(FILLER);
        vm.expectRevert(MockTarget.MockError.selector);
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);
    }

    function test_executeMessages_storesFulfillment() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessages_reverts_ifMsgValueTooHigh() external {
        TestMessage memory m = _initMessage(false, false);

        vm.deal(FILLER, 1);
        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Inbox.InvalidValue.selector, 0, 1));
        inbox.executeMessages{value: 1}(m.sourceChain, m.sender, m.messages, m.attributes);
    }

    function test_executeMessages_emitsEvent() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        vm.expectEmit(true, true, false, false);
        emit CallFulfilled({requestHash: m.messageId, fulfilledBy: FILLER});
        inbox.executeMessages(m.sourceChain, m.sender, m.messages, m.attributes);
    }

    function test_storeExecutionReceipt_reverts_invalidCaller() external {
        vm.expectRevert(RIP7755Inbox.InvalidCaller.selector);
        inbox.storeExecutionReceipt(bytes32(0), FILLER);
    }

    function _initMessage(bool isPrecheck, bool isUserOp) private view returns (TestMessage memory) {
        string memory sourceChain = CAIP2.local();
        string memory sender = address(this).toChecksumHexString();
        bytes[] memory attributes = new bytes[](isPrecheck ? 7 : 6);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, bytes32(0), uint256(0));
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, FILLER);
        attributes[5] = abi.encodeWithSelector(_USER_OP_ATTRIBUTE_SELECTOR, isUserOp);

        if (isPrecheck) {
            attributes[6] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR, address(precheck));
        }

        return TestMessage({
            messageId: inbox.getRequestId(sourceChain, sender, new Message[](0), attributes),
            sourceChain: sourceChain,
            sender: sender,
            messages: new Message[](0),
            attributes: attributes
        });
    }

    function _appendMessage(TestMessage memory m, Message memory message) private pure {
        Message[] memory messages = new Message[](m.messages.length + 1);
        for (uint256 i = 0; i < m.messages.length; i++) {
            messages[i] = m.messages[i];
        }
        messages[m.messages.length] = message;
        m.messages = messages;
    }
}
