import {
  decodeEventLog,
  toHex,
  type Address,
  type Block,
  type Log,
} from "viem";
const { ssz } = await import("@lodestar/types");
const { SignedBeaconBlock } = ssz.deneb;

import ArbitrumRollup from "../abis/ArbitrumRollup";
import AnchorStateRegistry from "../abis/AnchorStateRegistry";
import {
  SupportedChains,
  type ActiveChains,
  type DecodedNodeCreatedLog,
  type GetBeaconRootAndL2TimestampReturnType,
  type L2Block,
} from "../common/types/chain";
import type ConfigService from "../config/config.service";
import RIP7755Inbox from "../abis/RIP7755Inbox";
import type { FulfillmentInfoType } from "../common/types/fulfillmentInfo";
import safeFetch from "../common/utils/safeFetch";
import exponentialBackoff from "../common/utils/exponentialBackoff";

export default class ChainService {
  constructor(
    private readonly activeChains: ActiveChains,
    private readonly configService: ConfigService
  ) {}

  async getBeaconRootAndL2Timestamp(): Promise<GetBeaconRootAndL2TimestampReturnType> {
    console.log("getBeaconRootAndL2Timestamp");
    const config = this.activeChains.src;
    const block: L2Block = await exponentialBackoff(
      async () => await config.publicClient.getBlock()
    );

    return {
      beaconRoot: block.parentBeaconBlockRoot,
      timestampForL2BeaconOracle: block.timestamp,
    };
  }

  async getBeaconBlock(tag: string): Promise<any> {
    console.log("getBeaconBlock");
    const beaconApiUrl = this.configService.getOrThrow("NODE");
    const url = `${beaconApiUrl}/eth/v2/beacon/blocks/${tag}`;
    const req = { headers: { Accept: "application/octet-stream" } };
    const resp = await exponentialBackoff(
      async () => await safeFetch(url, req),
      { successCallback: (res) => res && res.status === 200 }
    );

    if (!resp) {
      throw new Error("Error fetching Beacon Block");
    }

    if (resp.status === 404) {
      throw new Error(`Missing block ${tag}`);
    }

    if (resp.status !== 200) {
      throw new Error(`error fetching block ${tag}: ${await resp.text()}`);
    }

    const raw = new Uint8Array(await resp.arrayBuffer());
    const signedBlock = SignedBeaconBlock.deserialize(raw);
    return signedBlock.message;
  }

  async getL1Block(): Promise<Block> {
    return await this.activeChains.l1.publicClient.getBlock();
  }

  async getL2Block(blockNumber?: bigint): Promise<{
    l2Block: Block;
    sendRoot?: Address;
    nodeIndex?: bigint;
  }> {
    console.log("getL2Block");

    switch (this.activeChains.dst.chainId) {
      case SupportedChains.ArbitrumSepolia:
        return await this.getArbitrumSepoliaBlock();
      case SupportedChains.OptimismSepolia:
      case SupportedChains.MockOptimism:
        if (!blockNumber) {
          throw new Error(
            "Block number is required for Optimism Sepolia Block retrieval"
          );
        }

        return await this.getOptimismSepoliaBlock(blockNumber);
      default:
        throw new Error("Received unknown chain in getL2Block");
    }
  }

  private async getArbitrumSepoliaBlock(): Promise<{
    l2Block: Block;
    sendRoot: Address;
    nodeIndex: bigint;
  }> {
    console.log("getArbitrumSepoliaBlock");
    // Need to get blockHash instead
    // 1. Get latest node from Rollup contract
    const nodeIndex: bigint = await exponentialBackoff(async () => {
      return await this.activeChains.l1.publicClient.readContract({
        address: this.activeChains.dst.l2Oracle,
        abi: ArbitrumRollup,
        functionName: "latestConfirmed",
      });
    });

    // 2. Query event from latest node creation
    const logs = await this.getLogs(nodeIndex);
    if (logs.length === 0) {
      throw new Error("Error finding Arb Rollup Log");
    }
    const topics = decodeEventLog({
      abi: ArbitrumRollup,
      data: logs[0].data,
      topics: logs[0].topics,
    }) as unknown as DecodedNodeCreatedLog;

    if (!topics.args) {
      throw new Error("Error decoding NodeCreated log");
    }
    if (!topics.args.assertion) {
      throw new Error("Error: assertion field not found in decoded log");
    }

    // 3. Grab assertion from Node event
    const assertion = topics.args.assertion;

    // 4. Parse blockHash from assertion
    const blockHash = assertion.afterState.globalState.bytes32Vals[0];
    const sendRoot = assertion.afterState.globalState.bytes32Vals[1];
    const l2Block = await exponentialBackoff(async () => {
      return await this.activeChains.dst.publicClient.getBlock({
        blockHash,
      });
    });
    return { l2Block, sendRoot, nodeIndex };
  }

  private async getOptimismSepoliaBlock(
    blockNumber: bigint
  ): Promise<{ l2Block: Block }> {
    const l2BlockNumber = await this.getL2BlockNumber(blockNumber);
    const l2Block = await exponentialBackoff(async () => {
      return await this.activeChains.dst.publicClient.getBlock({
        blockNumber: l2BlockNumber,
      });
    });
    return { l2Block };
  }

  private async getLogs(index: bigint): Promise<Log[]> {
    const etherscanApiKey = this.configService.getOrThrow("ETHERSCAN_API_KEY");
    const url = `https://api-sepolia.etherscan.io/api?module=logs&action=getLogs&address=${
      this.activeChains.dst.l2Oracle
    }&topic0=0x4f4caa9e67fb994e349dd35d1ad0ce23053d4323f83ce11dc817b5435031d096&topic0_1_opr=and&topic1=${toHex(
      index,
      { size: 32 }
    )}&page=1&apikey=${etherscanApiKey}`;

    return await this.request(url);
  }

  private async getL2BlockNumber(l1BlockNumber: bigint): Promise<bigint> {
    const config = this.activeChains.l1;
    const [, l2BlockNumber]: [any, bigint] = await exponentialBackoff(
      async () => {
        return await config.publicClient.readContract({
          address: this.activeChains.dst.l2Oracle,
          abi: AnchorStateRegistry,
          functionName: "anchors",
          args: [0n],
          blockNumber: l1BlockNumber,
        });
      }
    );
    return l2BlockNumber;
  }

  async getOutboxLogs(
    fromBlock: number,
    outboxAddress: Address
  ): Promise<Log[]> {
    const apiKey = this.activeChains.src.etherscanApiKey;
    const url = `${this.activeChains.src.etherscanApiUrl}/api?module=logs&action=getLogs&address=${outboxAddress}&topic0=0x513fade1f2861a5deef5d7a92a5b2ca923eae36c137aa45ebe2ecc62ae3fbf07&page=1&apikey=${apiKey}&fromBlock=${fromBlock}`;

    return await this.request(url);
  }

  async getFulfillmentInfo(requestHash: Address): Promise<FulfillmentInfoType> {
    const config = this.activeChains.dst;
    return await exponentialBackoff(async () => {
      return await config.publicClient.readContract({
        address: config.contracts.inbox,
        abi: RIP7755Inbox,
        functionName: "getFulfillmentInfo",
        args: [requestHash],
      });
    });
  }

  private async request(url: string): Promise<any> {
    const res = await exponentialBackoff(async () => await safeFetch(url), {
      successCallback: (res) => res && res.ok,
    });

    if (res === null || !res.ok) {
      throw new Error("Error fetching logs from etherscan");
    }

    const json = await res.json();

    return json.result;
  }
}
