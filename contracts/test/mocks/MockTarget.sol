// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockTarget {
    error MockError();

    uint256 public number;

    function target(uint256 num) external {
        number = num;
    }

    function shouldFail() external pure {
        revert MockError();
    }
}
