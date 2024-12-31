// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {DeployRIP7755Inbox} from "../script/DeployRIP7755Inbox.s.sol";
import {CAIP10} from "../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StringsHelper} from "../src/libraries/StringsHelper.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call} from "../src/RIP7755Structs.sol";

import {MockPrecheck} from "./mocks/MockPrecheck.sol";
import {MockTarget} from "./mocks/MockTarget.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract RIP7755InboxTest is BaseTest {
    using GlobalTypes for address;
    using CAIP10 for address;
    using StringsHelper for address;

    struct Message {
        bytes32 messageId;
        string sourceChain;
        string sender;
        bytes payload;
        bytes[] attributes;
    }

    RIP7755Inbox inbox;
    MockPrecheck precheck;
    MockTarget target;

    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    function setUp() public {
        DeployRIP7755Inbox deployer = new DeployRIP7755Inbox();
        inbox = deployer.run();
        precheck = new MockPrecheck();
        target = new MockTarget();
    }

    function test_executeMessage_storesFulfillment_withSuccessfulPrecheck() external {
        Message memory m = _initMessage(true);

        vm.prank(FILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessage_reverts_failedPrecheck() external {
        Message memory m = _initMessage(true);

        vm.expectRevert();
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_reverts_callAlreadyFulfilled() external {
        Message memory m = _initMessage(false);

        vm.prank(FILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755Inbox.CallAlreadyFulfilled.selector);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_callsTargetContract(uint256 inputNum) external {
        Message memory m = _initMessage(false);

        calls.push(
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.target.selector, inputNum),
                value: 0
            })
        );
        m.payload = abi.encode(calls);

        vm.prank(FILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        assertEq(target.number(), inputNum);
    }

    function test_executeMessage_sendsEth(uint256 amount) external {
        Message memory m = _initMessage(false);

        calls.push(Call({to: ALICE.addressToBytes32(), data: "", value: amount}));
        m.payload = abi.encode(calls);

        vm.deal(FILLER, amount);
        vm.prank(FILLER);
        inbox.executeMessage{value: amount}(m.sourceChain, m.sender, m.payload, m.attributes);

        assertEq(ALICE.balance, amount);
    }

    function test_executeMessage_reverts_ifTargetContractReverts() external {
        Message memory m = _initMessage(false);

        calls.push(
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.shouldFail.selector),
                value: 0
            })
        );
        m.payload = abi.encode(calls);

        vm.prank(FILLER);
        vm.expectRevert(MockTarget.MockError.selector);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_storesFulfillment() external {
        Message memory m = _initMessage(false);

        vm.prank(FILLER);
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessage_reverts_ifMsgValueTooHigh() external {
        Message memory m = _initMessage(false);

        vm.deal(FILLER, 1);
        vm.prank(FILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Inbox.InvalidValue.selector, 0, 1));
        inbox.executeMessage{value: 1}(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function test_executeMessage_emitsEvent() external {
        Message memory m = _initMessage(false);

        vm.prank(FILLER);
        vm.expectEmit(true, true, false, false);
        emit CallFulfilled({requestHash: m.messageId, fulfilledBy: FILLER});
        inbox.executeMessage(m.sourceChain, m.sender, m.payload, m.attributes);
    }

    function _initMessage(bool isPrecheck) private view returns (Message memory) {
        string memory sourceChain = CAIP10.formatCaip2(block.chainid);
        string memory sender = address(this).toChecksumHexString();
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](isPrecheck ? 6 : 5);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, bytes32(0), uint256(0));
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, FILLER);

        if (isPrecheck) {
            attributes[5] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR, address(precheck));
        }

        return Message({
            messageId: inbox.getMessageId(sourceChain, sender, payload, attributes),
            sourceChain: sourceChain,
            sender: sender,
            payload: payload,
            attributes: attributes
        });
    }
}
