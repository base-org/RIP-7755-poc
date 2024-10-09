// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IPrecheckContract} from "./IPrecheckContract.sol";
import {CrossChainCall, FulfillmentInfo} from "./RIP7755Structs.sol";

/// @title RIP7755Verifier
///
/// @author Coinbase (https://github.com/base-org/7755-poc)
///
/// @notice A Verification contract within RIP-7755.
///
/// This contract's sole purpose is to route requested transactions on destination chains and store record of their fulfillment.
contract RIP7755Verifier {
    error RIP7755Verifier__InvalidChainId();
    error RIP7755Verifier__InvalidVerifyingContract();
    error RIP7755Verifier__CallAlreadyFulfilled();

    event CallFulfilled(bytes32 indexed callHash, address indexed fulfilledBy);

    mapping(bytes32 callHash => FulfillmentInfo) private fillInfo;

    /// @notice Returns the stored fulfillment info for a passed in call hash
    ///
    /// @param _callHash A keccak256 hash of a CrossChainCall request
    ///
    /// @return _ Fulfillment info stored for the call hash
    function getFillInfo(bytes32 _callHash) external view returns (FulfillmentInfo memory) {
        return fillInfo[_callHash];
    }

    /// @notice A fulfillment entrypoint for RIP7755 cross chain calls.
    ///
    /// @param _request A cross chain call request formatted following the RIP-7755 spec. See {RIP7755Structs-CrossChainCall}.
    function fulfill(CrossChainCall calldata _request) external payable {
        if (block.chainid != _request.destinationChainId) {
            revert RIP7755Verifier__InvalidChainId();
        }

        if (address(this) != _request.verifyingContract) {
            revert RIP7755Verifier__InvalidVerifyingContract();
        }

        // Run precheck - call expected to revert if precheck condition(s) not met.
        if (_request.precheckContract != address(0)) {
            IPrecheckContract(_request.precheckContract).precheckCall(_request, msg.sender);
        }

        // TODO: Check for trusted originationContract

        bytes32 _callHash = callHashCalldata(_request);

        if (fillInfo[_callHash].timestamp != 0) {
            revert RIP7755Verifier__CallAlreadyFulfilled();
        }

        for (uint256 i; i < _request.calls.length; i++) {
            _call(_request.calls[i].to, _request.calls[i].value, _request.calls[i].data);
        }

        fillInfo[_callHash] = FulfillmentInfo({timestamp: uint96(block.timestamp), filler: msg.sender});

        emit CallFulfilled({callHash: _callHash, fulfilledBy: msg.sender});
    }

    /// @notice Hashes a cross chain call request.
    ///
    /// @param _request A cross chain call request formatted following the RIP-7755 spec. See {RIP7755Structs-CrossChainCall}.
    ///
    /// @return _ A keccak256 hash of the cross chain call request.
    function callHashCalldata(CrossChainCall calldata _request) public pure returns (bytes32) {
        return keccak256(abi.encode(_request));
    }

    function _call(address _target, uint256 _value, bytes memory _data) internal {
        (bool _success, bytes memory _result) = _target.call{value: _value}(_data);
        if (!_success) {
            assembly ("memory-safe") {
                revert(add(_result, 32), mload(_result))
            }
        }
    }
}
