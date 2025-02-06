// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {CAIP2} from "openzeppelin-contracts/contracts/utils/CAIP2.sol";
import {CAIP10} from "openzeppelin-contracts/contracts/utils/CAIP10.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {RRC7755Base} from "../src/RRC7755Base.sol";

import {MockBeaconOracle} from "./mocks/MockBeaconOracle.sol";

contract BaseTest is Test, RRC7755Base {
    ERC20Mock mockErc20;
    MockBeaconOracle mockBeaconOracle;

    address approveAddr;

    address ALICE = makeAddr("alice");
    address FILLER = makeAddr("filler");
    address BUNDLER = makeAddr("bundler");
    string rootPath;
    string validProof;
    string invalidL1State;
    string invalidBlockHeaders;
    string invalidL2StateRootProof;
    string invalidL2Storage;

    uint256 constant _REWARD_AMOUNT = 1 ether;
    bytes32 constant _VERIFIER_STORAGE_LOCATION = 0xfd1017d80ffe8da8a74488ee7408c9efa1877e094afa95857de95797c1228500;

    /// @notice The selector for the nonce attribute
    bytes4 internal constant _NONCE_ATTRIBUTE_SELECTOR = 0xce03fdab; // nonce(uint256)

    /// @notice The selector for the reward attribute
    bytes4 internal constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount

    /// @notice The selector for the delay attribute
    bytes4 internal constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry

    /// @notice The selector for the requester attribute
    bytes4 internal constant _REQUESTER_ATTRIBUTE_SELECTOR = 0x3bd94e4c; // requester(bytes32)

    /// @notice The selector for the l2Oracle attribute
    bytes4 internal constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)

    /// @notice The selector for the shoyuBashi attribute
    bytes4 internal constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    /// @notice The selector for the inbox attribute
    bytes4 internal constant _INBOX_ATTRIBUTE_SELECTOR = 0xbd362374; // inbox(bytes32)

    /// @notice The selector for the destinationChain attribute
    bytes4 internal constant _DESTINATION_CHAIN_SELECTOR = 0xdff49bf1; // destinationChain(bytes32)

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

    modifier fundAccount(address account, uint256 amount) {
        mockErc20.mint(account, amount);
        vm.deal(account, amount);
        vm.prank(account);
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

    function _getMessageId(
        string memory sourceChain,
        string memory sender,
        Call[] memory calls,
        bytes[] memory attributes
    ) internal pure returns (bytes32) {
        string memory combinedSender = CAIP10.format(sourceChain, sender);
        return keccak256(abi.encode(combinedSender, _remote(111112), calls, attributes));
    }

    // Including to block from coverage report
    function test() external {}
}
