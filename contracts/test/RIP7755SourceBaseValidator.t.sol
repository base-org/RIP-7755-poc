// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {DeployRIP7755SourceBaseValidator} from "../script/DeployRIP7755SourceBaseValidator.s.sol";
import {RIP7755SourceBaseValidator} from "../src/RIP7755SourceBaseValidator.sol";
import {Call, CrossChainRequest} from "../src/RIP7755Structs.sol";

contract RIP7755SourceBaseValidatorTest is Test {
    RIP7755SourceBaseValidator sourceContract;
    ERC20Mock mockErc20;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() external {
        DeployRIP7755SourceBaseValidator deployer = new DeployRIP7755SourceBaseValidator();
        sourceContract = deployer.run();
        mockErc20 = new ERC20Mock();
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(address(sourceContract), amount);
        _;
    }
}
