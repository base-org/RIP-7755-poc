// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {RIP7755Source} from "../src/RIP7755Source.sol";
import {Call, CrossChainCall} from "../src/RIP7755Structs.sol";

import {MockSource} from "./mocks/MockSource.sol";

contract RIP7755SourceTest is Test {
    MockSource mockSource;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event CrossChainCallRequested(bytes32 indexed callHash, CrossChainCall call);

    function setUp() public {
        mockSource = new MockSource();
        mockErc20 = new ERC20Mock();
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(mockSource), amount);
        _;
    }

    function test_requestCrossChainCall_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAmount /= 2;
        bytes32 callHash = mockSource.hashCalldataCall(request);
        CrossChainCall memory call = mockSource.convertToCrossChainCall(request);
        call.nonce++;

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(callHash, call);
        mockSource.requestCrossChainCall(request);

        call.nonce++;

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(callHash, call);
        mockSource.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_reverts_ifInvalidNativeCurrency(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RIP7755Source.InvalidValue.selector, rewardAmount, 0));
        mockSource.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_setStatusToRequested_erc20Reward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        bytes32 requestHash = mockSource.hashCalldataCall(request);
        assert(mockSource.getRequestStatus(requestHash) == RIP7755Source.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        request.rewardAsset = _NATIVE_ASSET;

        vm.prank(ALICE);
        mockSource.requestCrossChainCall{value: rewardAmount}(request);

        bytes32 requestHash = mockSource.hashCalldataCall(request);
        assert(mockSource.getRequestStatus(requestHash) == RIP7755Source.CrossChainCallStatus.Requested);
    }

    function test_requestCrossChainCall_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);
        bytes32 callHash = mockSource.hashCalldataCall(request);
        CrossChainCall memory call = mockSource.convertToCrossChainCall(request);
        call.nonce++;

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit CrossChainCallRequested(callHash, call);
        mockSource.requestCrossChainCall(request);
    }

    function test_requestCrossChainCall_pullsERC20FromUserIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_requestCrossChainCall_pullsERC20IntoContractIfUsed(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(mockSource));

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        uint256 contractBalAfter = mockErc20.balanceOf(address(mockSource));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function _initRequest(uint256 rewardAmount) private view returns (RIP7755Source.CrossChainRequest memory) {
        return RIP7755Source.CrossChainRequest({
            calls: calls,
            destinationChainId: 0,
            verifyingContract: address(0),
            l2Oracle: address(0),
            l2OracleStorageKey: bytes32(0),
            rewardAsset: address(mockErc20),
            rewardAmount: rewardAmount,
            finalityDelaySeconds: 10,
            nonce: 0,
            precheckContract: address(0),
            precheckData: ""
        });
    }
}
