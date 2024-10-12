// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {DeployRIP7755Verifier} from "../script/DeployRIP7755Verifier.s.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";
import {RIP7755Verifier} from "../src/RIP7755Verifier.sol";

import {MockPrecheck} from "./mocks/MockPrecheck.sol";
import {MockTarget} from "./mocks/MockTarget.sol";

contract RIP7755VerifierTest is Test {
    RIP7755Verifier verifier;
    MockPrecheck precheck;
    MockTarget target;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FULFILLER = makeAddr("fulfiller");

    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    function setUp() public {
        DeployRIP7755Verifier deployer = new DeployRIP7755Verifier();
        verifier = deployer.run();
        precheck = new MockPrecheck();
        target = new MockTarget();
    }

    function test_fulfill_reverts_invalidChainId() external {
        CrossChainRequest memory request = _initRequest();

        request.destinationChainId = 0;

        vm.prank(FULFILLER);
        vm.expectRevert(RIP7755Verifier.InvalidChainId.selector);
        verifier.fulfill(request, FULFILLER);
    }

    function test_fulfill_reverts_invalidDestinationAddress() external {
        CrossChainRequest memory request = _initRequest();

        request.verifyingContract = address(0);

        vm.prank(FULFILLER);
        vm.expectRevert(RIP7755Verifier.InvalidVerifyingContract.selector);
        verifier.fulfill(request, FULFILLER);
    }

    function test_fulfill_storesFulfillment_withSuccessfulPrecheck() external {
        CrossChainRequest memory request = _initRequest();

        request.precheckContract = address(precheck);
        request.precheckData = abi.encode(FULFILLER);

        vm.prank(FULFILLER);
        verifier.fulfill(request, FULFILLER);

        bytes32 requestHash = verifier.hashRequest(request);
        RIP7755Verifier.FulfillmentInfo memory info = verifier.getFulfillmentInfo(requestHash);

        assertEq(info.filler, FULFILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_fulfill_reverts_failedPrecheck() external {
        CrossChainRequest memory request = _initRequest();

        request.precheckContract = address(precheck);
        request.precheckData = abi.encode(address(0));

        vm.prank(FULFILLER);
        vm.expectRevert();
        verifier.fulfill(request, FULFILLER);
    }

    function test_reverts_callAlreadyFulfilled() external {
        CrossChainRequest memory request = _initRequest();

        vm.prank(FULFILLER);
        verifier.fulfill(request, FULFILLER);

        vm.prank(FULFILLER);
        vm.expectRevert(RIP7755Verifier.CallAlreadyFulfilled.selector);
        verifier.fulfill(request, FULFILLER);
    }

    function test_fulfill_callsTargetContract(uint256 inputNum) external {
        CrossChainRequest memory request = _initRequest();
        calls.push(
            Call({to: address(target), data: abi.encodeWithSelector(target.target.selector, inputNum), value: 0})
        );
        request.calls = calls;

        vm.prank(FULFILLER);
        verifier.fulfill(request, FULFILLER);

        assertEq(target.number(), inputNum);
    }

    function test_fulfill_reverts_ifTargetContractReverts() external {
        CrossChainRequest memory request = _initRequest();
        calls.push(Call({to: address(target), data: abi.encodeWithSelector(target.shouldFail.selector), value: 0}));
        request.calls = calls;

        vm.prank(FULFILLER);
        vm.expectRevert(MockTarget.MockError.selector);
        verifier.fulfill(request, FULFILLER);
    }

    function test_fulfill_storesFulfillment() external {
        CrossChainRequest memory request = _initRequest();

        vm.prank(FULFILLER);
        verifier.fulfill(request, FULFILLER);

        bytes32 requestHash = verifier.hashRequest(request);
        RIP7755Verifier.FulfillmentInfo memory info = verifier.getFulfillmentInfo(requestHash);

        assertEq(info.filler, FULFILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_fulfill_emitsEvent() external {
        CrossChainRequest memory request = _initRequest();
        bytes32 requestHash = verifier.hashRequest(request);

        vm.prank(FULFILLER);
        vm.expectEmit(true, true, false, false);
        emit CallFulfilled({requestHash: requestHash, fulfilledBy: FULFILLER});
        verifier.fulfill(request, FULFILLER);
    }

    function _initRequest() private view returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: ALICE,
            calls: calls,
            originationContract: address(0),
            originChainId: 0,
            destinationChainId: block.chainid,
            verifyingContract: address(verifier),
            l2Oracle: address(0),
            l2OracleStorageKey: bytes32(0),
            rewardAsset: address(0),
            rewardAmount: 0,
            finalityDelaySeconds: 0,
            nonce: 0,
            expiry: 0,
            precheckContract: address(0),
            precheckData: ""
        });
    }
}
