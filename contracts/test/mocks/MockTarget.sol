// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockTarget {
    error MockTarget__Error();

    uint256 public number;

    function target(uint256 _num) external {
        number = _num;
    }

    function shouldFail() external pure {
        revert MockTarget__Error();
    }
}
