// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EntryPoint, IEntryPoint, PackedUserOperation, UserOperationLib} from "account-abstraction/core/EntryPoint.sol";
import {Vm} from "forge-std/Vm.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {BaseTest} from "./BaseTest.t.sol";
import {MockAccount} from "./mocks/MockAccount.sol";
import {MockEndpoint} from "./mocks/MockEndpoint.sol";
import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {MockUserOpPrecheck} from "./mocks/MockUserOpPrecheck.sol";

contract PaymasterTest is BaseTest, MockEndpoint {
    using UserOperationLib for PackedUserOperation;
    using ECDSA for bytes32;

    IEntryPoint entryPoint;
    MockAccount account;
    RIP7755Inbox inbox;
    Paymaster paymaster;
    address precheck;

    Vm.Wallet signer = vm.createWallet(block.timestamp);

    event ClaimAddressSet(address indexed claimAddress);

    function setUp() external {
        entryPoint = IEntryPoint(new EntryPoint());
        account = new MockAccount();
        inbox = new RIP7755Inbox(address(entryPoint));

        vm.prank(signer.addr);
        paymaster = Paymaster(payable(inbox.deployPaymaster()));
        approveAddr = address(paymaster);
        precheck = address(new MockUserOpPrecheck());

        _setUp();
    }

    modifier fundPaymaster(address account, uint256 amount) {
        vm.prank(account);
        (bool success,) = payable(paymaster).call{value: amount}("");
        assertTrue(success);
        _;
    }

    function test_deployment_reverts_zeroAddressEntryPoint() external {
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        new Paymaster(address(0), signer.addr);
    }

    function test_deployment_reverts_zeroAddressOwner() external {
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        new Paymaster(address(entryPoint), address(0));
    }

    function test_deployment_reverts_zeroAddressBoth() external {
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        new Paymaster(address(0), address(0));
    }

    function test_entryPointDeposit_revertsIfNotCalledByOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        paymaster.entryPointDeposit(1);
    }

    function test_entryPointDeposit_routesToEntryPoint(uint256 amount) public fundAccount(signer.addr, amount) {
        uint256 initialBalance = address(entryPoint).balance;

        vm.prank(signer.addr);
        paymaster.entryPointDeposit{value: amount}(amount);

        assertEq(address(entryPoint).balance, initialBalance + amount);
    }

    function test_entryPointDeposit_storesBalanceInEntryPointOnBehalfOfPaymaster(uint256 amount)
        public
        fundAccount(signer.addr, amount)
    {
        uint256 initialBalance = entryPoint.getDepositInfo(address(paymaster)).deposit;

        vm.prank(signer.addr);
        paymaster.entryPointDeposit{value: amount}(amount);

        assertEq(entryPoint.getDepositInfo(address(paymaster)).deposit, initialBalance + amount);
    }

    function test_withdrawTo_revertsIfNotCalledByOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        paymaster.withdrawTo(payable(address(0)), 1);
    }

    function test_withdrawTo_revertsIfWithdrawAddressIsZeroAddress() public {
        vm.prank(signer.addr);
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        paymaster.withdrawTo(payable(address(0)), 1);
    }

    function test_withdrawTo_withdrawsFromEntryPoint(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        _deposit(amount);
        uint256 initialBalance = address(entryPoint).balance;

        vm.prank(signer.addr);
        paymaster.withdrawTo(payable(ALICE), amount);

        assertEq(address(entryPoint).balance, initialBalance - amount);
    }

    function test_withdrawTo_sendsFundsToWithdrawAddress(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        uint256 initialBalance = payable(ALICE).balance;

        _deposit(amount);

        vm.prank(signer.addr);
        paymaster.withdrawTo(payable(ALICE), amount);

        assertEq(payable(ALICE).balance, initialBalance + amount);
    }

    function test_setClaimAddress_revertsIfNotCalledByOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        paymaster.setClaimAddress(address(0));
    }

    function test_setClaimAddress_revertsIfClaimAddressIsZeroAddress() public {
        vm.prank(signer.addr);
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        paymaster.setClaimAddress(address(0));
    }

    function test_setClaimAddress_setsClaimAddress(address newClaimAddress) public {
        vm.assume(newClaimAddress != address(0));

        address startClaimAddress = paymaster.claimAddress();

        vm.prank(signer.addr);
        paymaster.setClaimAddress(newClaimAddress);

        assertEq(startClaimAddress, signer.addr);
        assertEq(paymaster.claimAddress(), newClaimAddress);
    }

    function test_setClaimAddress_emitsClaimAddressSetEvent() public {
        address newClaimAddress = address(0x123);

        vm.expectEmit(true, true, false, false);
        emit ClaimAddressSet(newClaimAddress);

        vm.prank(signer.addr);
        paymaster.setClaimAddress(newClaimAddress);
    }

    function test_entryPointAddStake_revertsIfNotCalledByOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        paymaster.entryPointAddStake(1);
    }

    function test_entryPointAddStake_addsStakeToEntryPoint(uint112 amount) public fundAccount(signer.addr, amount) {
        vm.assume(amount > 0);

        uint256 initialStake = entryPoint.getDepositInfo(address(paymaster)).stake;

        vm.prank(signer.addr);
        paymaster.entryPointAddStake{value: amount}(1);

        assertEq(entryPoint.getDepositInfo(address(paymaster)).stake, initialStake + amount);
    }

    function test_entryPointUnlockStake_revertsIfNotCalledByOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        paymaster.entryPointUnlockStake();
    }

    function test_entryPointUnlockStake_unlocksStake(uint112 amount) public fundAccount(signer.addr, amount) {
        vm.assume(amount > 0);

        vm.prank(signer.addr);
        paymaster.entryPointAddStake{value: 1}(1);

        vm.prank(signer.addr);
        paymaster.entryPointUnlockStake();

        assertEq(entryPoint.getDepositInfo(address(paymaster)).withdrawTime, block.timestamp + 1);
        assertEq(entryPoint.getDepositInfo(address(paymaster)).staked, false);
    }

    function test_entryPointWithdrawStake_revertsIfNotCalledByOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        paymaster.entryPointWithdrawStake(payable(address(0)));
    }

    function test_entryPointWithdrawStake_withdrawsStake(uint112 amount) public fundAccount(signer.addr, amount) {
        vm.assume(amount > 0);

        vm.startPrank(signer.addr);
        paymaster.entryPointAddStake{value: amount}(1);
        paymaster.entryPointUnlockStake();

        vm.warp(block.timestamp + 1);

        paymaster.entryPointWithdrawStake(payable(ALICE));
        vm.stopPrank();

        assertEq(payable(ALICE).balance, amount);
    }

    function test_validatePaymasterUserOp_revertsIfNotCalledByEntryPoint(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) public {
        vm.expectRevert(Paymaster.NotEntryPoint.selector);
        paymaster.validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }

    function test_validatePaymasterUserOp_revertsIfInvalidSignature(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        PackedUserOperation[] memory userOps = _generateUserOps(1000, amount, address(0));
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(maxCost <= amount && amount <= type(uint256).max - maxCost);
        _deposit(maxCost);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA33 reverted",
                abi.encodeWithSelector(
                    Paymaster.InvalidSignature.selector, 0x7F1d642DbfD62aD4A8fA9810eA619707d09825D0, signer.addr
                )
            )
        );
        entryPoint.handleOps(userOps, payable(BUNDLER));
    }

    function test_validatePaymasterUserOp_revertsIfFulfillerDoesNotHaveEnoughBalance(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        PackedUserOperation[] memory userOps = _generateUserOps(signer.privateKey, amount, address(0));
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        _deposit(amount);

        vm.assume(maxCost <= amount && amount <= type(uint256).max - maxCost);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA33 reverted",
                abi.encodeWithSelector(Paymaster.InsufficientBalance.selector, 0, amount)
            )
        );
        entryPoint.handleOps(userOps, payable(BUNDLER));
    }

    function test_validatePaymasterUserOp_incrementsWithdrawableBalance(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        PackedUserOperation[] memory userOps = _generateUserOps(signer.privateKey, ethAmount, address(0));
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = address(paymaster).balance;

        entryPoint.handleOps(userOps, payable(BUNDLER));

        assertEq(address(paymaster).balance, initialBalance - ethAmount);
    }

    function test_validatePaymasterUserOp_storesExecutionReceipt(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(signer.privateKey, ethAmount, address(0));
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = address(paymaster).balance;

        entryPoint.handleOps(userOps, payable(BUNDLER));

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo =
            inbox.getFulfillmentInfo(entryPoint.getUserOpHash(userOps[0]));

        assertEq(fulfillmentInfo.fulfiller, address(signer.addr));
        assertNotEq(fulfillmentInfo.timestamp, 0);
    }

    function test_validatePaymasterUserOp_doesNotStoreExecutionReceiptIfOpFails(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        uint256 ethAmount = 0;
        PackedUserOperation[] memory userOps = _generateUserOps(signer.privateKey, ethAmount, address(0));
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = address(paymaster).balance;

        entryPoint.handleOps(userOps, payable(BUNDLER));

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo =
            inbox.getFulfillmentInfo(entryPoint.getUserOpHash(userOps[0]));

        assertEq(fulfillmentInfo.fulfiller, address(0));
        assertEq(fulfillmentInfo.timestamp, 0);
    }

    function test_validatePaymasterUserOp_revertsIfPrecheckFails(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(signer.privateKey, ethAmount, precheck);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = address(paymaster).balance;

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOpWithRevert.selector, 0, "AA33 reverted", ""));
        entryPoint.handleOps(userOps, payable(BUNDLER));
    }

    function _generateUserOps(uint256 signerKey, uint256 ethAmount, address precheck)
        private
        returns (PackedUserOperation[] memory)
    {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = PackedUserOperation({
            sender: address(account),
            nonce: 0,
            initCode: "",
            callData: abi.encodeWithSelector(MockAccount.executeUserOp.selector, address(paymaster)),
            accountGasLimits: bytes32(abi.encodePacked(uint128(1000000), uint128(1000000))),
            preVerificationGas: 100000,
            gasFees: bytes32(abi.encodePacked(uint128(1000000), uint128(1000000))),
            paymasterAndData: "",
            signature: abi.encode(0)
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, _genDigest(userOps[0], ethAmount).toEthSignedMessageHash());
        userOps[0].paymasterAndData =
            _encodePaymasterAndData(address(paymaster), abi.encodePacked(r, s, v), ethAmount, precheck);
        return userOps;
    }

    function _encodePaymasterAndData(address paymaster, bytes memory signature, uint256 ethAmount, address precheck)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(paymaster, uint128(1000000), uint128(1000000), abi.encode(ethAmount, signature, precheck));
    }

    function _genDigest(PackedUserOperation memory userOp, uint256 ethAmount) private view returns (bytes32) {
        uint256 dstChainId = block.chainid;
        return keccak256(abi.encode(userOp.sender, userOp.nonce, userOp.callData, ethAmount, dstChainId));
    }

    function calculateMaxCost(PackedUserOperation calldata userOp) public view returns (uint256) {
        MemoryUserOp memory mUserOp;
        _copyUserOpToMemory(userOp, mUserOp);
        return _getRequiredPrefund(mUserOp);
    }

    function _deposit(uint256 amount) private {
        vm.prank(signer.addr);
        paymaster.entryPointDeposit(amount);
    }
}
