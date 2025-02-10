// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RRC7755Base} from "../../src/RRC7755Base.sol";
import {RRC7755Inbox} from "../../src/RRC7755Inbox.sol";

contract SubmitToInbox is Script, RRC7755Base {
    using GlobalTypes for address;

    bytes4 internal constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount
    bytes4 internal constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry
    bytes4 internal constant _NONCE_ATTRIBUTE_SELECTOR = 0xce03fdab; // nonce(uint256)
    bytes4 internal constant _REQUESTER_ATTRIBUTE_SELECTOR = 0x3bd94e4c; // requester(bytes32)
    bytes4 internal constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    function run() external {
        RRC7755Inbox inbox = RRC7755Inbox(payable(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512));
        address fulfiller = 0x23214A0864FC0014CAb6030267738F01AFfdd547;

        (bytes32 sourceChain, bytes32 sender, bytes memory payload, bytes[] memory attributes) = _initMessage();

        vm.startBroadcast();
        inbox.fulfill(sourceChain, sender, payload, attributes, fulfiller);
        vm.stopBroadcast();
    }

    // Using dummy values for local testing
    function _initMessage() private pure returns (bytes32, bytes32, bytes memory, bytes[] memory) {
        Call[] memory calls = new Call[](0);

        bytes32 sourceChain = bytes32(uint256(31337));
        bytes32 sender = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496.addressToBytes32();
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](5);

        attributes[0] = abi.encodeWithSelector(
            _REWARD_ATTRIBUTE_SELECTOR, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, 1 ether
        );
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(
            _REQUESTER_ATTRIBUTE_SELECTOR, 0x000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6
        );
        attributes[4] = abi.encodeWithSelector(
            _SHOYU_BASHI_ATTRIBUTE_SELECTOR, 0x0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f
        );

        return (sourceChain, sender, payload, attributes);
    }

    // Including to block from coverage report
    function test() external {}
}
