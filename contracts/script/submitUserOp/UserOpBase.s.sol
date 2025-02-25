// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {StandardBase} from "../requests/StandardBase.s.sol";

import {MockAccount} from "../../test/mocks/MockAccount.sol";

contract UserOpBase is StandardBase {
    using GlobalTypes for address;

    address private constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    function _initMessage(uint256 destinationChainId, uint256 duration, uint256 nonce)
        internal
        virtual
        override
        returns (bytes32, bytes32, bytes memory, bytes[] memory)
    {
        (bytes32 destinationChain,,, bytes[] memory attributes) =
            super._initMessage(destinationChainId, duration, nonce);
        HelperConfig.NetworkConfig memory dstConfig = helperConfig.getConfig(destinationChainId);

        address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        uint128 verificationGasLimit = 100000;
        uint128 callGasLimit = 100000;
        uint128 maxPriorityFeePerGas = 100000;
        uint128 maxFeePerGas = 100000;

        vm.createSelectFork(dstConfig.rpcUrl);
        uint256 entryPointNonce = EntryPoint(payable(ENTRY_POINT)).getNonce(dstConfig.smartAccount, 0);

        bytes32 receiver = ENTRY_POINT.addressToBytes32();

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: dstConfig.smartAccount,
            nonce: entryPointNonce,
            initCode: "",
            callData: abi.encodeWithSelector(MockAccount.executeUserOp.selector, address(dstConfig.inbox), ethAddress),
            accountGasLimits: bytes32(abi.encodePacked(verificationGasLimit, callGasLimit)),
            preVerificationGas: 100000,
            gasFees: bytes32(abi.encodePacked(maxPriorityFeePerGas, maxFeePerGas)),
            paymasterAndData: _encodePaymasterAndData(dstConfig.inbox, attributes, ethAddress),
            signature: ""
        });

        return (destinationChain, receiver, abi.encode(userOp), new bytes[](0));
    }

    function _encodePaymasterAndData(address inbox, bytes[] memory attributes, address ethAddress)
        private
        pure
        returns (bytes memory)
    {
        address precheck = address(0);
        uint256 ethAmount = 0.0001 ether;
        uint128 paymasterVerificationGasLimit = 100000;
        uint128 paymasterPostOpGasLimit = 100000;
        return abi.encodePacked(
            inbox,
            paymasterVerificationGasLimit,
            paymasterPostOpGasLimit,
            abi.encode(ethAddress, ethAmount, precheck, attributes)
        );
    }

    // Including to block from coverage report
    function test_userOp_base() external {}
}
