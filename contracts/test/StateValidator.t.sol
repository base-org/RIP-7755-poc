// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {StateValidator} from "../src/libraries/StateValidator.sol";
import {MockStateValidator} from "./mocks/MockStateValidator.sol";

contract StateValidatorTest is Test {
    MockStateValidator mockStateValidator;

    function setUp() public {
        mockStateValidator = new MockStateValidator();
    }

    function test_validateState_reverts_oracleCallFails() external {
        deployCodeTo("MockStateValidator.sol", abi.encode(), 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02);
        vm.expectRevert(abi.encodeWithSelector(StateValidator.BeaconRootsOracleCallFailed.selector, abi.encode(1)));
        mockStateValidator.validateState(
            address(0),
            StateValidator.StateProofParameters({
                beaconRoot: bytes32(uint256(1)),
                beaconOracleTimestamp: 1,
                executionStateRoot: bytes32(uint256(1)),
                stateRootProof: new bytes32[](0)
            }),
            StateValidator.AccountProofParameters({
                storageKey: abi.encode(uint256(1)),
                storageValue: abi.encode(uint256(1)),
                accountProof: new bytes[](0),
                storageProof: new bytes[](0)
            })
        );
    }

    function test_validateAccountStorage_reverts_ifInvalidAccountStructure() external {
        bytes memory encodedAccount =
            hex"f90224a0645c2c097705aef7a67aab8e7bebe9ccdef7277e1c4287e052d264444ed6118da01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794a4b000000000000000000073657175656e636572a04fce9af672aa9a624f43fcdecb7dc2f137220cf9e8a40f9555ac7df54bd82a42a0beec0b13d083ebbe53fe2ba98509acc5aa127e494e8b05dd1de851bcd675a5cea0b745fc54204ae8f5f8c600191da48237f2502c941dc4e8ec057d690651f96f8cb901000000002000000000000000020000a001400000000000000000800000000000000000280000000000000000000000000000000000000000000000000000200000000100000000000000080409000000008001000000000010000000800000010000000000020000000000000000000800008000000000004000000810000000400000000001000080000000000000280000040000000000001800000000200000020400400000800000000000000200000202000000000000000000000000000000008002000000200000000000000000000000000000000000000000000020000010000000240000000000000000004400100000480000000000020000100000018406fc59ae870400000000000083155208846792b144a00bf10cf6053bf44b0bf8e379d29072165857d5326142f5f2c7692d9bfbd1797fa0000000000000eedb0000000000734da000000000000000200000000000000000880000000000142f058405f5e100";
        vm.expectRevert(StateValidator.InvalidAccountRLP.selector);
        mockStateValidator.extractStorageRoot(encodedAccount);
    }
}
