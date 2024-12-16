// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest, Call} from "../../src/RIP7755Structs.sol";

contract SubmitToInbox is Script {
    using GlobalTypes for address;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        RIP7755Inbox inbox = RIP7755Inbox(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        CrossChainRequest memory request = _getRequest();

        vm.startBroadcast(pk);
        // TODO
        // inbox.fulfill(request, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.stopBroadcast();
    }

    // Using dummy values for local testing
    function _getRequest() private pure returns (CrossChainRequest memory) {
        bytes[] memory extraData = new bytes[](2);
        extraData[0] = abi.encode(address(0));
        extraData[1] = abi.encode(0x0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f);

        return CrossChainRequest({
            requester: 0x000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6,
            calls: new Call[](0),
            sourceChainId: 31337,
            origin: 0x0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496,
            destinationChainId: 111112,
            inboxContract: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512.addressToBytes32(),
            l2Oracle: bytes32(0),
            rewardAsset: 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a,
            rewardAmount: 1 ether,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 1828828574,
            extraData: extraData
        });
    }
}
