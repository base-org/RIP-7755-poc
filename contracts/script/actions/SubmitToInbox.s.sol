// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {CAIP10} from "../../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {ERC7786Base} from "../../src/ERC7786Base.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest, Call} from "../../src/RIP7755Structs.sol";

contract SubmitToInbox is Script, ERC7786Base {
    using GlobalTypes for address;
    using CAIP10 for address;

    bytes4 private constant _SHOYUBASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        RIP7755Inbox inbox = RIP7755Inbox(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        (string memory sender, bytes memory payload, bytes[] memory attributes) = _initMessage();

        vm.startBroadcast(pk);
        inbox.executeMessage("", sender, payload, attributes);
        vm.stopBroadcast();
    }

    // Using dummy values for local testing
    function _initMessage() private view returns (string memory, bytes memory, bytes[] memory) {
        Call[] memory calls = new Call[](0);

        string memory sender = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512.local();
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](6);

        attributes[0] = abi.encodeWithSelector(
            _REWARD_ATTRIBUTE_SELECTOR, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, 1 ether
        );
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        attributes[2] = abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, bytes32(0));
        attributes[3] = abi.encodeWithSelector(
            _REQUESTER_ATTRIBUTE_SELECTOR, 0x000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6
        );
        attributes[4] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[5] = abi.encodeWithSelector(
            _SHOYUBASHI_ATTRIBUTE_SELECTOR, 0x0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f
        );

        return (sender, payload, attributes);
    }
}
