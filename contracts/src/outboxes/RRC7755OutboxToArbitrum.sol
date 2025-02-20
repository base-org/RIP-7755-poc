// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ArbitrumProver} from "../libraries/provers/ArbitrumProver.sol";
import {RRC7755Outbox} from "../RRC7755Outbox.sol";

/// @title RRC7755OutboxToArbitrum
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on
///         Arbitrum
contract RRC7755OutboxToArbitrum is RRC7755Outbox {
    using ArbitrumProver for bytes;

    /// @notice Returns the minimum amount of time before a request can expire
    function _minExpiryTime(uint256) internal pure override returns (uint256) {
        return 8 days;
    }

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at verifyingContractStorageKey on request.verifyingContract
    /// @custom:reverts If the L2StorageRoot does not correspond to our validated L1 storage slot
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes of the request
    /// @param proof                   The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proof
    ) internal view override {
        bytes calldata l2OracleAttribute = _locateAttribute(attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        address l2Oracle = abi.decode(l2OracleAttribute[4:], (address));
        proof.validate(
            ArbitrumProver.Target({l1Address: l2Oracle, l2Address: inbox, l2StorageKey: inboxContractStorageKey})
        );
    }
}
