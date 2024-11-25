// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest, Call} from "../../src/RIP7755Structs.sol";

contract SubmitToInbox is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        RIP7755Inbox inbox = RIP7755Inbox(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        CrossChainRequest memory request = _getRequest();

        vm.startBroadcast(pk);
        inbox.fulfill(request, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.stopBroadcast();
    }

    function _getRequest() private pure returns (CrossChainRequest memory) {
        return CrossChainRequest({
            requester: 0x328809Bc894f92807417D2dAD6b7C998c1aFdac6,
            calls: new Call[](0),
            destinationChainId: 111112,
            inboxContract: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, // RIP7755Inbox on mock Chain B
            l2Oracle: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, // Anchor State Registry on mock L1
            l2OracleStorageKey: 0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49, // Anchor State Registry storage slot
            rewardAsset: 0x2e234DAe75C793f67A35089C9d99245E1C58470b,
            rewardAmount: 1 ether,
            finalityDelaySeconds: 10,
            nonce: 1,
            expiry: 1828828574,
            extraData: new bytes[](0)
        });
    }
}
