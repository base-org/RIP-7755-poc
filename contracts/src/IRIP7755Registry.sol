// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title RIP7755Registry Interface
///
/// @notice An interface for the RIP-7755 registry contract. This interface defines the methods
/// that allow contracts to check, add, or remove trusted origination contracts.
interface IRIP7755Registry {
    
    /// @notice Checks if a given origination contract is trusted
    ///
    /// @param originationContract The address of the origination contract
    ///
    /// @return _ A status indicating whether the contract is trusted
    function checkTrustedContract(address originationContract) external view returns (bool);

    /// @notice Adds an origination contract to the trusted list
    ///
    /// @param originationContract The address of the origination contract to be trusted
    function addTrustedContract(address originationContract) external;

    /// @notice Removes an origination contract from the trusted list
    ///
    /// @param originationContract The address of the origination contract to be removed
    function removeTrustedContract(address originationContract) external;
}
