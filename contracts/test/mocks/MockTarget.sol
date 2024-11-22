// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MockTarget {
    error MockError();

    uint256 public number;

    function target(uint256 num) external {
        number = num;
    }

    function shouldFail() external pure {
        revert MockError();
    }

    // Including to block from coverage report
    function test() external {}
}
