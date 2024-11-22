// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";
import {CrossChainRequest, Call} from "../../src/RIP7755Structs.sol";

contract SubmitRequest is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        RIP7755Outbox outbox = RIP7755Outbox(0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2);
        Call[] memory calls = new Call[](1);
        calls[0] = Call({to: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721, value: 1, data: ""});

        CrossChainRequest memory request = CrossChainRequest({
            requester: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721,
            calls: calls,
            destinationChainId: 84532, // base sepolia chain ID
            inboxContract: 0xB482b292878FDe64691d028A2237B34e91c7c7ea, // RIP7755Inbox on Base Sepolia
            l2Oracle: 0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205, // Base Sepolia AnchorStateRegistry on Sepolia
            l2OracleStorageKey: 0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49, // AnchorStateRegistry storage slot
            rewardAsset: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            rewardAmount: 2,
            finalityDelaySeconds: 1 weeks,
            nonce: 0,
            expiry: block.timestamp + 2 weeks,
            extraData: new bytes[](0)
        });

        vm.startBroadcast(pk);
        outbox.requestCrossChainCall{value: request.rewardAmount}(request);
        vm.stopBroadcast();
    }
}
