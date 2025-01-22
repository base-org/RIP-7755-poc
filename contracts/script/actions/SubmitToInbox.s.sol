// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {CAIP2} from "openzeppelin-contracts/contracts/utils/CAIP2.sol";

import {ERC7786Base} from "../../src/ERC7786Base.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";

contract SubmitToInbox is Script, ERC7786Base {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        RIP7755Inbox inbox = RIP7755Inbox(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        (string memory sourceChain, string memory sender, Message[] memory messages, bytes[] memory attributes) =
            _initMessage();

        vm.startBroadcast(pk);
        inbox.executeMessages(sourceChain, sender, messages, attributes);
        vm.stopBroadcast();
    }

    // Using dummy values for local testing
    function _initMessage() private pure returns (string memory, string memory, Message[] memory, bytes[] memory) {
        Message[] memory calls = new Message[](0);

        string memory sourceChain = CAIP2.format("eip155", "31337");
        string memory sender = "0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496";
        bytes[] memory attributes = new bytes[](6);

        attributes[0] = abi.encodeWithSelector(
            _REWARD_ATTRIBUTE_SELECTOR, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, 1 ether
        );
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(
            _REQUESTER_ATTRIBUTE_SELECTOR, 0x000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6
        );
        attributes[4] =
            abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, 0x23214A0864FC0014CAb6030267738F01AFfdd547);
        attributes[5] = abi.encodeWithSelector(
            _SHOYU_BASHI_ATTRIBUTE_SELECTOR, 0x0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f
        );

        return (sourceChain, sender, calls, attributes);
    }
}
