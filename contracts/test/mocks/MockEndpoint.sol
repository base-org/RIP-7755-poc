// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {UserOperationLib} from "account-abstraction/core/UserOperationLib.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

contract MockEndpoint {
    struct MemoryUserOp {
        address sender;
        uint256 nonce;
        uint256 verificationGasLimit;
        uint256 callGasLimit;
        uint256 paymasterVerificationGasLimit;
        uint256 paymasterPostOpGasLimit;
        uint256 preVerificationGas;
        address paymaster;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
    }

    function _copyUserOpToMemory(PackedUserOperation calldata userOp, MemoryUserOp memory mUserOp) internal pure {
        mUserOp.sender = userOp.sender;
        mUserOp.nonce = userOp.nonce;
        (mUserOp.verificationGasLimit, mUserOp.callGasLimit) = UserOperationLib.unpackUints(userOp.accountGasLimits);
        mUserOp.preVerificationGas = userOp.preVerificationGas;
        (mUserOp.maxPriorityFeePerGas, mUserOp.maxFeePerGas) = UserOperationLib.unpackUints(userOp.gasFees);
        bytes calldata paymasterAndData = userOp.paymasterAndData;
        if (paymasterAndData.length > 0) {
            require(paymasterAndData.length >= UserOperationLib.PAYMASTER_DATA_OFFSET, "AA93 invalid paymasterAndData");
            (mUserOp.paymaster, mUserOp.paymasterVerificationGasLimit, mUserOp.paymasterPostOpGasLimit) =
                UserOperationLib.unpackPaymasterStaticFields(paymasterAndData);
        } else {
            mUserOp.paymaster = address(0);
            mUserOp.paymasterVerificationGasLimit = 0;
            mUserOp.paymasterPostOpGasLimit = 0;
        }
    }

    function _getRequiredPrefund(MemoryUserOp memory mUserOp) internal pure returns (uint256 requiredPrefund) {
        unchecked {
            uint256 requiredGas = mUserOp.verificationGasLimit + mUserOp.callGasLimit
                + mUserOp.paymasterVerificationGasLimit + mUserOp.paymasterPostOpGasLimit + mUserOp.preVerificationGas;

            requiredPrefund = requiredGas * mUserOp.maxFeePerGas;
        }
    }
}
