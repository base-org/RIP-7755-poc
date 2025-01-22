// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {CAIP2} from "openzeppelin-contracts/contracts/utils/CAIP2.sol";
import {CAIP10} from "openzeppelin-contracts/contracts/utils/CAIP10.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {ERC7786Base} from "../src/ERC7786Base.sol";
import {Call} from "../src/RIP7755Structs.sol";

import {MockBeaconOracle} from "./mocks/MockBeaconOracle.sol";

contract BaseTest is Test, ERC7786Base {
    ERC20Mock mockErc20;
    MockBeaconOracle mockBeaconOracle;

    address approveAddr;

    Call[] calls;
    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    string rootPath;
    string validProof;
    string invalidL1State;
    string invalidBlockHeaders;
    string invalidL2StateRootProof;
    string invalidL2Storage;

    uint256 constant _REWARD_AMOUNT = 1 ether;
    bytes32 constant _VERIFIER_STORAGE_LOCATION = 0x43f1016e17bdb0194ec37b77cf476d255de00011d02616ab831d2e2ce63d9ee2;

    function _setUp() internal {
        mockErc20 = new ERC20Mock();

        deployCodeTo("MockBeaconOracle.sol", abi.encode(), 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02);
        mockBeaconOracle = MockBeaconOracle(0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02);

        rootPath = vm.projectRoot();
    }

    modifier fundAlice(uint256 amount) {
        mockErc20.mint(ALICE, amount);
        vm.deal(ALICE, amount);
        vm.prank(ALICE);
        mockErc20.approve(approveAddr, amount);
        _;
    }

    function _deriveStorageKey(bytes32 messageId) internal pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
    }

    function _remote(address addr, uint256 chainId) internal pure returns (string memory) {
        return CAIP10.format(CAIP2.format("eip155", Strings.toString(chainId)), Strings.toChecksumHexString(addr));
    }

    function _remote(uint256 chainId) internal pure returns (string memory) {
        return CAIP2.format("eip155", Strings.toString(chainId));
    }
}
