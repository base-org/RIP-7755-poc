// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {IPaymaster} from "account-abstraction/interfaces/IPaymaster.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IInbox} from "./interfaces/IInbox.sol";
import {IUserOpPrecheck} from "./interfaces/IUserOpPrecheck.sol";

/// @title Paymaster
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract is used as a hook for fulfillers to provide funds for requested transactions when the
///         cross-chain call(s) are ERC-4337 User Operations
contract Paymaster is IPaymaster, Ownable {
    using ECDSA for bytes32;
    using SafeTransferLib for address payable;

    /// @notice The ERC-4337 EntryPoint contract
    IEntryPoint public immutable ENTRY_POINT;

    /// @notice The RRC-7755 Inbox contract
    IInbox public immutable INBOX;

    /// @notice The address of the claim address
    address public claimAddress;

    /// @notice A mapping from an account's address to the amount of eth that can be withdrawn by the account. This is
    ///         used to track the amount of eth that has been allocated by the paymaster but not yet withdrawn by the
    ///         account
    mapping(address account => uint256) private _withdrawable;

    /// @notice This error is thrown when an address is the zero address
    error ZeroAddress();

    /// @notice This error is thrown when the sender is not the EntryPoint contract
    error NotEntryPoint();

    /// @notice This error is thrown when the recovered address does not match the owner's address
    ///
    /// @param recovered The address that was recovered from the signature
    /// @param expected  The address that was expected to be recovered from the signature
    error InvalidSignature(address recovered, address expected);

    /// @notice This error is thrown when a fulfiller does not have enough balance to cover the cost of a User Operation
    ///
    /// @param balance The balance of the fulfiller
    /// @param amount  The amount of eth that is required to cover the cost of the User Operation
    error InsufficientBalance(uint256 balance, uint256 amount);

    /// @notice This error is thrown when the amount of eth to withdraw is zero
    error ZeroAmount();

    /// @notice This event is emitted when a fulfiller's claim address is set
    ///
    /// @param claimAddress The address that the fulfiller is allowed to claim rewards from
    event ClaimAddressSet(address indexed claimAddress);

    /// @dev Stores entrypoint and initializes owner. Expected to be deployed by the RRC-7755 Inbox contract
    ///
    /// @custom:reverts If the EntryPoint contract or owner address is the zero address
    ///
    /// @param _entryPoint        The EntryPoint contract to use for the paymaster
    /// @param _owner             The address of the owner of the paymaster
    /// @param _entryPointDeposit The amount of eth to deposit on the EntryPoint contract
    constructor(address _entryPoint, address _owner, uint256 _entryPointDeposit) payable {
        if (address(_entryPoint) == address(0) || _owner == address(0)) {
            revert ZeroAddress();
        }

        ENTRY_POINT = IEntryPoint(_entryPoint);
        INBOX = IInbox(msg.sender);
        _initializeOwner(_owner);
        claimAddress = _owner;

        if (_entryPointDeposit > 0) {
            payable(_entryPoint).safeTransferETH(_entryPointDeposit);
        }
    }

    /// @dev A modifier that ensures the caller is the EntryPoint contract
    modifier onlyEntryPoint() {
        if (msg.sender != address(ENTRY_POINT)) {
            revert NotEntryPoint();
        }
        _;
    }

    /// @notice A receive function that allows fulfillers to deposit eth into the paymaster
    receive() external payable {}

    /// @notice Transfers ETH from this contract into the EntryPoint.
    ///
    /// @dev Reverts if not called by the owner of the contract.
    ///
    /// @param amount The amount to deposit on the the Entrypoint.
    function entryPointDeposit(uint256 amount) external payable onlyOwner {
        payable(address(ENTRY_POINT)).safeTransferETH(amount);
    }

    /// @notice A function that allows a fulfiller to withdraw eth from the paymaster
    ///
    /// @custom:reverts If the withdraw address is the zero address
    ///
    /// @param withdrawAddress The address to withdraw the eth to
    /// @param amount          The amount of eth to withdraw
    function withdrawTo(address payable withdrawAddress, uint256 amount) external onlyOwner {
        if (withdrawAddress == address(0)) {
            revert ZeroAddress();
        }

        ENTRY_POINT.withdrawTo(withdrawAddress, amount);
    }

    /// @notice A function that allows a fulfiller to set their claim address
    ///
    /// @param fulfillerClaimAddress The address to set as the claim address
    function setClaimAddress(address fulfillerClaimAddress) external onlyOwner {
        if (fulfillerClaimAddress == address(0)) {
            revert ZeroAddress();
        }

        claimAddress = fulfillerClaimAddress;

        emit ClaimAddressSet(fulfillerClaimAddress);
    }

    /// @notice Adds stake to the EntryPoint.
    ///
    /// @dev Reverts if not called by the owner of the contract. Calling this while an unstake
    ///      is pending will first cancel the pending unstake.
    ///
    /// @param unstakeDelaySeconds The duration for which the stake cannot be withdrawn. Must be
    ///                            equal to or greater than the current unstake delay.
    function entryPointAddStake(uint32 unstakeDelaySeconds) external payable onlyOwner {
        ENTRY_POINT.addStake{value: msg.value}(unstakeDelaySeconds);
    }

    /// @notice Unlocks stake in the EntryPoint.
    ///
    /// @dev Reverts if not called by the owner of the contract.
    function entryPointUnlockStake() external onlyOwner {
        ENTRY_POINT.unlockStake();
    }

    /// @notice Withdraws stake from the EntryPoint.
    ///
    /// @dev Reverts if not called by the owner of the contract. Only call this after the unstake delay
    ///      has passed since the last `entryPointUnlockStake` call.
    ///
    /// @param to The beneficiary address.
    function entryPointWithdrawStake(address payable to) external onlyOwner {
        ENTRY_POINT.withdrawStake(to);
    }

    /// @notice A function that validates a User Operation and returns the context and validation data
    ///
    /// @custom:reverts If the sender is not the EntryPoint contract
    /// @custom:reverts If the signature is not from the contract owner
    /// @custom:reverts If the precheck contract is not the zero address and the precheck reverts
    /// @custom:reverts If the fulfiller does not have enough balance to cover the cost of the User Operation
    ///
    /// @param userOp     The User Operation to validate
    /// @param userOpHash The hash of the User Operation
    ///
    /// @return context        The context for the User Operation
    /// @return validationData The validation data for the User Operation
    function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256)
        external
        onlyEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        (uint256 ethAmount, bytes memory signature, address precheckContract) =
            abi.decode(userOp.paymasterAndData[52:], (uint256, bytes, address));
        bytes32 digest = _genDigest(userOp, ethAmount);

        address fulfiller = digest.toEthSignedMessageHash().recover(signature);
        address expectedFulfiller = owner();

        if (fulfiller != expectedFulfiller) {
            revert InvalidSignature(fulfiller, expectedFulfiller);
        }

        uint256 balance = address(this).balance;

        if (ethAmount > balance) {
            revert InsufficientBalance(balance, ethAmount);
        }

        if (precheckContract != address(0)) {
            IUserOpPrecheck(precheckContract).precheckUserOp(userOp, fulfiller);
        }

        _withdrawable[userOp.sender] += ethAmount;

        return (abi.encode(userOpHash, claimAddress, userOp.sender), 0);
    }

    /// @notice A function that allows a smart account to withdraw eth from the paymaster during its user operation
    ///         execution
    ///
    /// @custom:reverts If the withdrawable amount is 0
    function withdrawGasExcess() external {
        uint256 ethAmount = _withdrawable[msg.sender];

        if (ethAmount == 0) {
            revert ZeroAmount();
        }

        delete _withdrawable[msg.sender];
        payable(msg.sender).safeTransferETH(ethAmount);
    }

    /// @notice A function that is called after a User Operation is executed. This function is used to update the paymaster's
    ///         state and to set the fulfillment info for the User Operation
    ///
    /// @param mode    The mode of the User Operation
    /// @param context The context for the User Operation
    function postOp(PostOpMode mode, bytes calldata context, uint256, uint256) external {
        (bytes32 userOpHash, address claimAddr, address sender) = abi.decode(context, (bytes32, address, address));

        if (mode == PostOpMode.opSucceeded) {
            INBOX.storeExecutionReceipt(userOpHash, claimAddr);
        }

        delete _withdrawable[sender];
    }

    function _genDigest(PackedUserOperation calldata userOp, uint256 ethAmount) private view returns (bytes32) {
        uint256 dstChainId = block.chainid;
        return keccak256(abi.encode(userOp.sender, userOp.nonce, userOp.callData, ethAmount, dstChainId));
    }
}
