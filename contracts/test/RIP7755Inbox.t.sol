// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {DeployRIP7755Inbox} from "../script/DeployRIP7755Inbox.s.sol";
import {CAIP10} from "../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StringsHelper} from "../src/libraries/StringsHelper.sol";
import {ERC7786Base} from "../src/ERC7786Base.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call} from "../src/RIP7755Structs.sol";

import {MockPrecheck} from "./mocks/MockPrecheck.sol";
import {MockTarget} from "./mocks/MockTarget.sol";

contract RIP7755InboxTest is Test, ERC7786Base {
    using GlobalTypes for address;
    using CAIP10 for address;
    using StringsHelper for address;

    struct Message {
        bytes32 messageId;
        string sourceChain;
        string sender;
        string combinedSender;
        string receiver;
        bytes payload;
        bytes[] attributes;
    }

    RIP7755Inbox inbox;
    MockPrecheck precheck;
    MockTarget target;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FULFILLER = makeAddr("fulfiller");

    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    function setUp() public {
        DeployRIP7755Inbox deployer = new DeployRIP7755Inbox();
        inbox = deployer.run();
        precheck = new MockPrecheck();
        target = new MockTarget();
    }

    function test_executeMessage_storesFulfillment_withSuccessfulPrecheck() external {
        Message memory m = _initMessage(0, true);

        vm.prank(FULFILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FULFILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessage_reverts_failedPrecheck() external {
        Message memory m = _initMessage(0, true);

        vm.expectRevert();
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_reverts_callAlreadyFulfilled() external {
        Message memory m = _initMessage(0, false);

        vm.prank(FULFILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        vm.prank(FULFILLER);
        vm.expectRevert(RIP7755Inbox.CallAlreadyFulfilled.selector);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_callsTargetContract(uint256 inputNum) external {
        Message memory m = _initMessage(0, false);

        calls.push(
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.target.selector, inputNum),
                value: 0
            })
        );
        m.payload = abi.encode(calls);

        vm.prank(FULFILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        assertEq(target.number(), inputNum);
    }

    function test_executeMessage_sendsEth(uint256 amount) external {
        Message memory m = _initMessage(0, false);

        calls.push(Call({to: ALICE.addressToBytes32(), data: "", value: amount}));
        m.payload = abi.encode(calls);

        vm.deal(FULFILLER, amount);
        vm.prank(FULFILLER);
        inbox.executeMessage{value: amount}(m.sourceChain, m.sender, m.payload, m.attributes);

        assertEq(ALICE.balance, amount);
    }

    function test_executeMessage_reverts_ifTargetContractReverts() external {
        Message memory m = _initMessage(0, false);

        calls.push(
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.shouldFail.selector),
                value: 0
            })
        );
        m.payload = abi.encode(calls);

        vm.prank(FULFILLER);
        vm.expectRevert(MockTarget.MockError.selector);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_storesFulfillment() external {
        Message memory m = _initMessage(0, false);

        vm.prank(FULFILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FULFILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessage_reverts_ifMsgValueTooHigh() external {
        Message memory m = _initMessage(0, false);

        vm.deal(FULFILLER, 1);
        vm.prank(FULFILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Inbox.InvalidValue.selector, 0, 1));
        inbox.executeMessage{value: 1}(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_emitsEvent() external {
        Message memory m = _initMessage(0, false);

        vm.prank(FULFILLER);
        vm.expectEmit(true, true, false, false);
        emit CallFulfilled({requestHash: m.messageId, fulfilledBy: FULFILLER});
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function _initMessage(uint256 rewardAmount, bool isPrecheck) private view returns (Message memory) {
        string memory sourceChain = CAIP10.formatCaip2(block.chainid);
        string memory sender = address(this).toChecksumHexString();
        string memory receiver = address(inbox).local();
        string memory combinedSender = CAIP10.format(sourceChain, sender);
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](isPrecheck ? 6 : 5);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, bytes32(0), rewardAmount);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, FULFILLER);

        if (isPrecheck) {
            attributes[5] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR, address(precheck));
        }

        return Message({
            messageId: keccak256(abi.encode(combinedSender, receiver, payload, attributes)),
            sourceChain: sourceChain,
            sender: sender,
            combinedSender: combinedSender,
            receiver: receiver,
            payload: payload,
            attributes: attributes
        });
    }
}
