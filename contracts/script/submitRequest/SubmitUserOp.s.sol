// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RRC7755Base} from "../../src/RRC7755Base.sol";
import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

import {MockAccount} from "../../test/mocks/MockAccount.sol";

contract SubmitUserOp is Script, RRC7755Base {
    using GlobalTypes for address;

    bytes4 internal constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount
    bytes4 internal constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry
    bytes4 internal constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)
    bytes4 internal constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)
    bytes4 internal constant _DESTINATION_CHAIN_SELECTOR = 0xdff49bf1; // destinationChain(bytes32)
    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    address ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    HelperConfig public helperConfig;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function run() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);

        address outboxAddr = config.opStackOutbox;
        uint256 destinationChainId = helperConfig.BASE_SEPOLIA_CHAIN_ID();
        uint256 duration = 1 weeks;

        RRC7755Outbox outbox = RRC7755Outbox(outboxAddr);

        (bytes32 destinationChain, bytes32 receiver, bytes memory payload) = _initMessage(destinationChainId, duration);

        vm.createSelectFork(config.rpcUrl);

        vm.startBroadcast();
        outbox.sendMessage{value: 0.0002 ether}(destinationChain, receiver, payload, new bytes[](0));
        vm.stopBroadcast();
    }

    function _initMessage(uint256 destinationChainId, uint256 duration)
        private
        returns (bytes32, bytes32, bytes memory)
    {
        HelperConfig.NetworkConfig memory dstConfig = helperConfig.getConfig(destinationChainId);
        // HelperConfig.NetworkConfig memory srcConfig = helperConfig.getConfig(block.chainid);

        address ethAddress = address(0);

        uint128 verificationGasLimit = 100000;
        uint128 callGasLimit = 100000;
        uint128 maxPriorityFeePerGas = 100000;
        uint128 maxFeePerGas = 100000;

        vm.createSelectFork(dstConfig.rpcUrl);
        uint256 nonce = EntryPoint(payable(ENTRY_POINT)).getNonce(dstConfig.smartAccount, 0);

        bytes32 destinationChain = bytes32(destinationChainId);
        bytes32 receiver = ENTRY_POINT.addressToBytes32();
        bytes[] memory attributes = new bytes[](3);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, 0.0002 ether);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, duration, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, dstConfig.l2Oracle);
        // attributes[2] = abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, srcConfig.shoyuBashi);
        // attributes[3] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, destinationChain);

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: dstConfig.smartAccount,
            nonce: nonce + 1,
            initCode: "",
            callData: abi.encodeWithSelector(MockAccount.executeUserOp.selector, address(dstConfig.inbox), ethAddress),
            accountGasLimits: bytes32(abi.encodePacked(verificationGasLimit, callGasLimit)),
            preVerificationGas: 100000,
            gasFees: bytes32(abi.encodePacked(maxPriorityFeePerGas, maxFeePerGas)),
            paymasterAndData: _encodePaymasterAndData(dstConfig.inbox, attributes, ethAddress),
            signature: ""
        });

        return (destinationChain, receiver, abi.encode(userOp));
    }

    function _encodePaymasterAndData(address inbox, bytes[] memory attributes, address ethAddress)
        private
        pure
        returns (bytes memory)
    {
        address precheck = address(0);
        uint256 ethAmount = 0.0001 ether;
        uint128 paymasterVerificationGasLimit = 100000;
        uint128 paymasterPostOpGasLimit = 100000;
        return abi.encodePacked(
            inbox,
            paymasterVerificationGasLimit,
            paymasterPostOpGasLimit,
            abi.encode(ethAddress, ethAmount, precheck, attributes)
        );
    }

    // Including to block from coverage report
    function test() external {}
}
