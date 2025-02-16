// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {SSZ} from "../src/libraries/SSZ.sol";
import {MockSSZ} from "./mocks/MockSSZ.sol";

contract SSZTest is Test {
    bytes32[] proof;
    bytes32 root;
    bytes32 leaf;
    uint256 index;

    MockSSZ ssz;

    function setUp() public {
        ssz = new MockSSZ();

        proof.push(0xd526ab81e92ee5f1cc067756a28fabace998cbcdc4dfc15be4e7a1e20556dd77);
        proof.push(0x91fef64270acd9eaa77515c225e1ff733405ad5c9ef6af09348a81d494d91153);
        proof.push(0xc29d2435ffdaae8e956a6ff850f93785e9088fc361df4b65fc4e5eda3dc48e5e);
        proof.push(0xdf1fe9c339af0ab637e1657df29f04f6013844ffa492e4f48679f688d298c96b);
        proof.push(0xd2ccf2d7b4fd6e881e9ef3eb79d21b67bf9541ad211e0a10568eedbec0a4c91c);
        proof.push(0x869e40e6d2a1efca3d0d6b9d199c1ee48a0b4a232e05431f30372bacc620dec1);
        proof.push(0xf17a619ac2d0dcc48af70c205dea3aba52c412df929f133f886ffbb6f52105b3);
        proof.push(0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71);
        proof.push(0x476ccb90633a03e07abffc0d8b9136e7428b938e1d99990dd57c8254869a2915);
        proof.push(0x0000000000000000000000000000000000000000000000000000000000000000);
        proof.push(0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b);
        proof.push(0x0398b3a4f9a61cdc13bcc5265c6860c6d6a13ce06d03d46663c0c54cf8bb4d01);
        root = 0xd19bacd555eff238f7c814e0eca799246746322f663c1811564ef07bc2b68dda;
        leaf = 0x4576ea3c05186e1df84e1c71036bf90bfc192f36063f6efed2a9c6fabe8de9db;
        index = 6434;
    }

    function test_verifyProof_returnsTrue() public view {
        assertEq(ssz.verifyProof(proof, root, leaf, index), true);
    }

    function test_verifyProof_reverts_invalidIndex() public {
        vm.expectRevert(0x5849603f);
        ssz.verifyProof(proof, root, leaf, 1);
    }

    function test_verifyProof_reverts_missingItem() public {
        vm.expectRevert(0x1b6661c3);
        ssz.verifyProof(new bytes32[](0), root, leaf, 2);
    }
}
