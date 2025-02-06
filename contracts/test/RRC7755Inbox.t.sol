// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {RRC7755Inbox} from "../src/RRC7755Inbox.sol";

import {MockPrecheck} from "./mocks/MockPrecheck.sol";
import {MockTarget} from "./mocks/MockTarget.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract RRC7755InboxTest is BaseTest {
    using GlobalTypes for address;

    struct TestMessage {
        bytes32 messageId;
        bytes32 sourceChain;
        bytes32 sender;
        bytes payload;
        bytes[] attributes;
    }

    RRC7755Inbox inbox;
    MockPrecheck precheck;
    MockTarget target;
    EntryPoint entryPoint;

    event PaymasterDeployed(address indexed sender, address indexed paymaster);
    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    function setUp() public {
        entryPoint = new EntryPoint();
        inbox = new RRC7755Inbox(address(entryPoint));
        precheck = new MockPrecheck();
        target = new MockTarget();
        approveAddr = address(inbox);
        _setUp();
    }

    function test_fulfill_reverts_userOp() external {
        TestMessage memory m = _initMessage(false, true);

        vm.expectRevert(RRC7755Inbox.UserOp.selector);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_storesFulfillment_withSuccessfulPrecheck() external {
        TestMessage memory m = _initMessage(true, false);

        vm.prank(FILLER, FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        RRC7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_fulfill_reverts_failedPrecheck() external {
        TestMessage memory m = _initMessage(true, false);

        vm.expectRevert();
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_reverts_callAlreadyFulfilled() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(RRC7755Inbox.CallAlreadyFulfilled.selector);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_callsTargetContract(uint256 inputNum) external {
        TestMessage memory m = _initMessage(false, false);

        _appendCall(
            m,
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.target.selector, inputNum),
                value: 0
            })
        );

        vm.prank(FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        assertEq(target.number(), inputNum);
    }

    function test_fulfill_sendsEth(uint256 amount) external {
        TestMessage memory m = _initMessage(false, false);

        _appendCall(m, Call({to: ALICE.addressToBytes32(), data: "", value: amount}));

        vm.deal(FILLER, amount);
        vm.prank(FILLER);
        inbox.fulfill{value: amount}(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        assertEq(ALICE.balance, amount);
    }

    function test_fulfill_reverts_ifTargetContractReverts() external {
        TestMessage memory m = _initMessage(false, false);

        _appendCall(
            m,
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.shouldFail.selector),
                value: 0
            })
        );

        vm.prank(FILLER);
        vm.expectRevert(MockTarget.MockError.selector);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_storesFulfillment() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        RRC7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_fulfill_reverts_ifMsgValueTooHigh() external {
        TestMessage memory m = _initMessage(false, false);

        vm.deal(FILLER, 1);
        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(Paymaster.InvalidValue.selector, 0, 1));
        inbox.fulfill{value: 1}(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_emitsEvent() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        vm.expectEmit(true, true, false, false);
        emit CallFulfilled({requestHash: m.messageId, fulfilledBy: FILLER});
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function _initMessage(bool isPrecheck, bool isUserOp) private view returns (TestMessage memory) {
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 sender = address(this).addressToBytes32();
        bytes memory payload = abi.encode(new Call[](0));
        bytes[] memory attributes = new bytes[](isPrecheck ? 6 : 5);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, bytes32(0), uint256(0));
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_USER_OP_ATTRIBUTE_SELECTOR, isUserOp);

        if (isPrecheck) {
            attributes[5] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR, address(precheck));
        }

        return TestMessage({
            messageId: inbox.getRequestId(
                sourceChain, sender, bytes32(block.chainid), address(inbox).addressToBytes32(), payload, attributes
            ),
            sourceChain: sourceChain,
            sender: sender,
            payload: payload,
            attributes: attributes
        });
    }

    function _appendCall(TestMessage memory m, Call memory call) private pure {
        Call[] memory currentCalls = abi.decode(m.payload, (Call[]));
        Call[] memory newCalls = new Call[](currentCalls.length + 1);
        for (uint256 i; i < currentCalls.length; i++) {
            newCalls[i] = currentCalls[i];
        }
        newCalls[currentCalls.length] = Call({to: call.to, value: call.value, data: call.data});
        m.payload = abi.encode(newCalls);
    }
}
