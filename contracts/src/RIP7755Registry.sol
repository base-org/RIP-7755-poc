// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

/// @title RIP7755Registry
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice A registry contract within RIP-7755. This contract serves as a registry for managing
/// and verifying trusted origination contracts.
contract RIP7755Registry is Ownable {
    using Address for address;

    /// @notice A mapping that tracks whether an origination contract is trusted
    mapping(address => bool) private _trustedContract;

    /// @notice Checks if a given origination contract is trusted
    ///
    /// @param originationContract The address of the origination contract
    ///
    /// @return _ A status indicating whether the contract is trusted
    function checkTrustedContract(address originationContract) external view returns (bool) {
        return _trustedContract[originationContract];
    }

    /// @notice Adds an origination contract to the trusted list
    ///
    /// @param originationContract The address of the origination contract to be trusted
    function addTrustedContract(address originationContract) external onlyOwner {
        _trustedContract[originationContract] = true;
    }

    /// @notice Removes an origination contract from the trusted list
    ///
    /// @param originationContract The address of the origination contract to be removed
    function removeTrustedContract(address originationContract) external onlyOwner {
        _trustedContract[originationContract] = false;
    }
}