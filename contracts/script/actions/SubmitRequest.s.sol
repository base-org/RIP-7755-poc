// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";
import {CrossChainRequest, Call} from "../../src/RIP7755Structs.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract SubmitRequest is Script {
    using GlobalTypes for address;

    HelperConfig public helperConfig;

    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function run() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);

        address outboxAddr = config.hashiOutbox;
        uint256 destinationChainId = helperConfig.BASE_SEPOLIA_CHAIN_ID();

        RIP7755Outbox outbox = RIP7755Outbox(outboxAddr);

        CrossChainRequest memory request = _getRequest(destinationChainId);

        vm.startBroadcast(config.deployerKey);
        outbox.requestCrossChainCall{value: request.rewardAmount}(request);
        vm.stopBroadcast();
    }

    function _getRequest(uint256 destinationChainId) private view returns (CrossChainRequest memory) {
        HelperConfig.NetworkConfig memory dstConfig = helperConfig.getConfig(destinationChainId);

        Call[] memory calls = new Call[](1);
        calls[0] =
            Call({to: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721.addressToBytes32(), data: "", value: 0.0001 ether});

        return CrossChainRequest({
            requester: bytes32(0),
            calls: calls,
            sourceChainId: 0,
            origin: bytes32(0),
            destinationChainId: dstConfig.chainId,
            inboxContract: dstConfig.inbox.addressToBytes32(),
            l2Oracle: dstConfig.l2Oracle.addressToBytes32(),
            rewardAsset: _NATIVE_ASSET,
            rewardAmount: 0.0002 ether,
            finalityDelaySeconds: 1 weeks,
            nonce: 0,
            expiry: block.timestamp + 2 weeks,
            extraData: new bytes[](0)
        });
    }
}
