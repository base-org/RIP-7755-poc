// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {CAIP10} from "../../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {StringsHelper} from "../../src/libraries/StringsHelper.sol";
import {ERC7786Base} from "../../src/ERC7786Base.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest, Call} from "../../src/RIP7755Structs.sol";

contract SubmitToInbox is Script, ERC7786Base {
    using GlobalTypes for address;
    using CAIP10 for address;
    using StringsHelper for address;

    bytes4 private constant _SHOYUBASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        RIP7755Inbox inbox = RIP7755Inbox(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        (string memory sourceChain, string memory sender, bytes memory payload, bytes[] memory attributes) =
            _initMessage();

        vm.startBroadcast(pk);
        inbox.executeMessage(sourceChain, sender, payload, attributes);
        vm.stopBroadcast();
    }

    // Using dummy values for local testing
    function _initMessage() private view returns (string memory, string memory, bytes memory, bytes[] memory) {
        Call[] memory calls = new Call[](0);

        string memory sourceChain = CAIP10.formatCaip2(11155420);
        string memory sender = 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874.toChecksumHexString();
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](6);

        attributes[0] = abi.encodeWithSelector(
            _REWARD_ATTRIBUTE_SELECTOR, 0x2e234DAe75C793f67A35089C9d99245E1C58470b.addressToBytes32(), 1 ether
        );
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(
            _REQUESTER_ATTRIBUTE_SELECTOR, 0x328809Bc894f92807417D2dAD6b7C998c1aFdac6.addressToBytes32()
        );
        attributes[4] =
            abi.encodeWithSelector(_FULFILLER_ATTRIBUTE_SELECTOR, 0x23214A0864FC0014CAb6030267738F01AFfdd547);
        attributes[5] =
            abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        return (sourceChain, sender, payload, attributes);
    }
}
