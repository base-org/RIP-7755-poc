import { decodeEventLog, toHex, type PublicClient } from "viem";
import { SupportedChains } from "../types/chains";
import clients from "../common/clients";
import addresses from "../common/addresses";
import ArbitrumRollup from "../abis/ArbitrumRollup.json";
import AnchorStateRegistry from "../abis/AnchorStateRegistry.json";
import type {
  DecodedNodeCreatedLog,
  GetBeaconRootAndL2TimestampReturnType,
  L2Block,
} from "../types/chain";
const { ssz } = await import("@lodestar/types");
const { SignedBeaconBlock } = ssz.deneb;

const BEACON_API_URL = process.env.NODE || "";

export default class ChainService {
  async getBeaconRootAndL2Timestamp(
    l2ChainPublicClient: PublicClient
  ): Promise<GetBeaconRootAndL2TimestampReturnType> {
    console.log("getBeaconRootAndL2Timestamp");
    const block = (await l2ChainPublicClient.getBlock()) as L2Block;
    return {
      beaconRoot: block.parentBeaconBlockRoot,
      timestampForL2BeaconOracle: block.timestamp,
    };
  }

  async getBeaconBlock(tag: string) {
    console.log("getBeaconBlock");
    const url = `${BEACON_API_URL}/eth/v2/beacon/blocks/${tag}`;
    const req = { headers: { Accept: "application/octet-stream" } };
    const resp = await fetch(url, req);

    if (resp.status === 404) {
      throw new Error(`Missing block ${tag}`);
    }

    if (resp.status != 200) {
      throw new Error(`error fetching block ${tag}: ${await resp.text()}`);
    }

    const raw = new Uint8Array(await resp.arrayBuffer());
    const signedBlock = SignedBeaconBlock.deserialize(raw);
    return signedBlock.message;
  }

  async getL2Block(chain: SupportedChains, blockNumber?: bigint) {
    console.log("getL2Block");

    switch (chain) {
      case SupportedChains.ArbitrumSepolia:
        return await this.getArbitrumSepoliaBlock();
      case SupportedChains.OptimismSepolia:
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

  private async getArbitrumSepoliaBlock() {
    console.log("getArbitrumSepoliaBlock");
    const { sepolia: sepoliaClient, arbitrumSepolia: arbitrumSepoliaClient } =
      clients;
    // Need to get blockHash instead
    // 1. Get latest node from Rollup contract
    const nodeIndex = (await sepoliaClient.readContract({
      address: addresses.sepolia.arbRollupAddr,
      abi: ArbitrumRollup,
      functionName: "latestConfirmed",
    })) as bigint;

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
    const l2Block = await arbitrumSepoliaClient.getBlock({ blockHash });
    return { l2Block, sendRoot, nodeIndex };
  }

  private async getOptimismSepoliaBlock(blockNumber: bigint) {
    const { optimismSepolia: optimismSepoliaClient } = clients;
    const l2BlockNumber = await this.getL2BlockNumber(blockNumber);
    const l2Block = await optimismSepoliaClient.getBlock({
      blockNumber: l2BlockNumber,
    });
    return { l2Block, sendRoot: null, nodeIndex: null };
  }

  private async getLogs(index: bigint) {
    const url = `https://api-sepolia.etherscan.io/api?module=logs&action=getLogs&address=${
      addresses.sepolia.arbRollupAddr
    }&topic0=0x4f4caa9e67fb994e349dd35d1ad0ce23053d4323f83ce11dc817b5435031d096&topic0_1_opr=and&topic1=${toHex(
      index,
      { size: 32 }
    )}&page=1&apikey=${process.env.ETHERSCAN_API_KEY}`;

    const res = await fetch(url);

    if (!res.ok) {
      throw new Error("Error fetching logs from etherscan");
    }

    const json = await res.json();

    if (json.result.length === 0) {
      throw new Error("No logs found from etherscan");
    }

    return json.result;
  }

  private async getL2BlockNumber(l1BlockNumber: bigint): Promise<bigint> {
    const { sepolia: sepoliaClient } = clients;
    const [, l2BlockNumber] = (await sepoliaClient.readContract({
      address: addresses.sepolia.anchorStateRegistryAddr,
      abi: AnchorStateRegistry,
      functionName: "anchors",
      args: [0n],
      blockNumber: l1BlockNumber,
    })) as [any, bigint];
    return l2BlockNumber;
  }
}
