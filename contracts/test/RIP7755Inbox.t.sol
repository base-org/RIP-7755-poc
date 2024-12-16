// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {DeployRIP7755Inbox} from "../script/DeployRIP7755Inbox.s.sol";
import {CAIP10} from "../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";

import {MockPrecheck} from "./mocks/MockPrecheck.sol";
import {MockTarget} from "./mocks/MockTarget.sol";

contract RIP7755InboxTest is Test {
    using GlobalTypes for address;
    using CAIP10 for address;

    RIP7755Inbox inbox;
    MockPrecheck precheck;
    MockTarget target;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FULFILLER = makeAddr("fulfiller");

    bytes4 private constant _PRECHECK_ATTRIBUTE_SELECTOR = 0xfa1e5831; // precheck(address)
    bytes4 private constant _NONCE_ATTRIBUTE_SELECTOR = 0xce03fdab; // nonce(uint256)
    bytes4 private constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount
    bytes4 private constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry
    bytes4 private constant _REQUESTER_ATTRIBUTE_SELECTOR = 0x3bd94e4c; // requester(bytes32)
    bytes4 private constant _FULFILLER_ATTRIBUTE_SELECTOR = 0x138a03fc; // fulfiller(address)

    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    function setUp() public {
        DeployRIP7755Inbox deployer = new DeployRIP7755Inbox();
        inbox = deployer.run();
        precheck = new MockPrecheck();
        target = new MockTarget();
    }

    function test_executeMessage_storesFulfillment_withSuccessfulPrecheck() external {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(0, true);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        vm.prank(FULFILLER);
        inbox.executeMessage("", sender, payload, attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(messageId);

        assertEq(info.fulfiller, FULFILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessage_reverts_failedPrecheck() external {
        (string memory sender,, bytes memory payload, bytes[] memory attributes) = _initMessage(0, true);

        vm.expectRevert();
        inbox.executeMessage("", sender, payload, attributes);
    }

    function test_executeMessage_reverts_callAlreadyFulfilled() external {
        (string memory sender,, bytes memory payload, bytes[] memory attributes) = _initMessage(0, false);

        vm.prank(FULFILLER);
        inbox.executeMessage("", sender, payload, attributes);

        vm.prank(FULFILLER);
        vm.expectRevert(RIP7755Inbox.CallAlreadyFulfilled.selector);
        inbox.executeMessage("", sender, payload, attributes);
    }

    function test_executeMessage_callsTargetContract(uint256 inputNum) external {
        (string memory sender,, bytes memory payload, bytes[] memory attributes) = _initMessage(0, false);

        calls.push(
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.target.selector, inputNum),
                value: 0
            })
        );
        payload = abi.encode(calls);

        vm.prank(FULFILLER);
        inbox.executeMessage("", sender, payload, attributes);

        assertEq(target.number(), inputNum);
    }

    function test_executeMessage_sendsEth(uint256 amount) external {
        (string memory sender,, bytes memory payload, bytes[] memory attributes) = _initMessage(0, false);

        calls.push(Call({to: ALICE.addressToBytes32(), data: "", value: amount}));
        payload = abi.encode(calls);

        vm.deal(FULFILLER, amount);
        vm.prank(FULFILLER);
        inbox.executeMessage{value: amount}("", sender, payload, attributes);

        assertEq(ALICE.balance, amount);
    }

    function test_executeMessage_reverts_ifTargetContractReverts() external {
        (string memory sender,, bytes memory payload, bytes[] memory attributes) = _initMessage(0, false);

        calls.push(
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.shouldFail.selector),
                value: 0
            })
        );
        payload = abi.encode(calls);

        vm.prank(FULFILLER);
        vm.expectRevert(MockTarget.MockError.selector);
        inbox.executeMessage("", sender, payload, attributes);
    }

    function test_executeMessage_storesFulfillment() external {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(0, false);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        vm.prank(FULFILLER);
        inbox.executeMessage("", sender, payload, attributes);

        RIP7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(messageId);

        assertEq(info.fulfiller, FULFILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_executeMessage_reverts_ifMsgValueTooHigh() external {
        (string memory sender,, bytes memory payload, bytes[] memory attributes) = _initMessage(0, false);

        vm.deal(FULFILLER, 1);
        vm.prank(FULFILLER);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Inbox.InvalidValue.selector, 0, 1));
        inbox.executeMessage{value: 1}("", sender, payload, attributes);
    }

    function test_executeMessage_emitsEvent() external {
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(0, false);
        bytes32 messageId = keccak256(abi.encode(sender, receiver, payload, attributes));

        vm.prank(FULFILLER);
        vm.expectEmit(true, true, false, false);
        emit CallFulfilled({requestHash: messageId, fulfilledBy: FULFILLER});
        inbox.executeMessage("", sender, payload, attributes);
    }

    function _initRequest() private view returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: ALICE.addressToBytes32(),
            calls: calls,
            sourceChainId: block.chainid,
            origin: address(this).addressToBytes32(),
            destinationChainId: block.chainid,
            inboxContract: address(inbox).addressToBytes32(),
            l2Oracle: address(0).addressToBytes32(),
            rewardAsset: address(0).addressToBytes32(),
            rewardAmount: 0,
            finalityDelaySeconds: 0,
            nonce: 0,
            expiry: 0,
            extraData: new bytes[](0)
        });
    }

    function _initMessage(uint256 rewardAmount, bool isPrecheck)
        private
        view
        returns (string memory, string memory, bytes memory, bytes[] memory)
    {
        string memory sender = address(this).local();
        string memory receiver = address(inbox).local();
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

        return (sender, receiver, payload, attributes);
    }
}
