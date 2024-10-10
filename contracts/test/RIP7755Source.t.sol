// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {RIP7755Source} from "../src/RIP7755Source.sol";
import {Call} from "../src/RIP7755Structs.sol";

import {MockSource} from "./mocks/MockSource.sol";

contract RIP7755SourceTest is Test {
    MockSource mockSource;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");

    function setUp() public {
        mockSource = new MockSource();
        mockErc20 = new ERC20Mock();
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(mockSource), amount);
        _;
    }

    function test_requestCrossChainCall_setStatusToRequested(uint256 rewardAmount) external fundAlice(rewardAmount) {
        RIP7755Source.CrossChainRequest memory request = _initRequest(rewardAmount);

        vm.prank(ALICE);
        mockSource.requestCrossChainCall(request);

        bytes32 requestHash = mockSource.hashCalldataCall(request);
        assert(mockSource.getRequestStatus(requestHash) == RIP7755Source.CrossChainCallStatus.Requested);
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
