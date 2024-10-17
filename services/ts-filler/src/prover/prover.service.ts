import {
  bytesToHex,
  encodeAbiParameters,
  keccak256,
  toHex,
  toRlp,
  type Address,
  type Block,
  type GetProofReturnType,
  type Hex,
} from "viem";
import type ChainService from "../chain/chain.service";
import clients from "../common/clients";
import config from "../config";
import { SupportedChains } from "../types/chains";
import addresses from "../common/addresses";
import constants from "../common/constants";
import type { GetBeaconRootAndL2TimestampReturnType } from "../chain/chain.service";
const { ssz } = await import("@lodestar/types");
const { BeaconBlock } = ssz.deneb;
const { createProof, ProofType } = await import(
  "@chainsafe/persistent-merkle-tree"
);

export type StateRootProofReturnType = { proof: Hex[]; leaf: Hex };

type Proofs = {
  storageProof: GetProofReturnType;
  l2StorageProof: GetProofReturnType;
  l2MessagePasserStorageProof?: GetProofReturnType;
};

type GetStorageProofsInput = {
  dstChain: SupportedChains;
  l1BlockNumber: bigint;
  l2Block: Block;
  l2Slot: Address;
  nodeIndex: bigint | null;
};

export default class ProverService {
  private readonly sourceClient: any;

  constructor(
    sourceChain: SupportedChains,
    private readonly chainService: ChainService
  ) {
    this.sourceClient = clients[sourceChain];
  }

  async generateProof() {
    const beaconData = await this.chainService.getBeaconRootAndL2Timestamp(
      this.sourceClient
    );
    const beaconBlock = await this.chainService.getBeaconBlock(
      beaconData.beaconRoot
    );
    const stateRootInclusion = this.getExecutionStateRootProof(beaconBlock);

    const dstChain = config.dstChain;
    const l1BlockNumber = BigInt(beaconBlock.body.executionPayload.blockNumber);

    const { l2Block, sendRoot, nodeIndex } = await this.chainService.getL2Block(
      dstChain,
      l1BlockNumber
    );
    const l2Slot = this.deriveRIP7755VerifierStorageSlot(config.requestHash);
    // const l2Slot = deriveOpSepoliaWethStorageSlot();

    // // Can be removed after testing /////
    if (dstChain === SupportedChains.OptimismSepolia) {
      // Target block on optimism sepolia
      const targetBlock = 18573292n;
      console.log({
        targetBlock,
        l2BlockNumber: l2Block.number,
        diff: targetBlock - l2Block.number,
      });
    }
    // /////////////////////////////////////

    const storageProofOpts = {
      dstChain,
      l1BlockNumber,
      l2Block,
      l2Slot,
      nodeIndex,
    };
    const storageProofs = await this.getStorageProofs(storageProofOpts);

    return await this.storeProofObj(
      storageProofs,
      l2Block,
      beaconData,
      stateRootInclusion,
      sendRoot,
      nodeIndex
    );
  }

  private getExecutionStateRootProof(block: any): StateRootProofReturnType {
    console.log("getExecutionStateRootProof");
    const blockView = BeaconBlock.toView(block);
    const path = ["body", "executionPayload", "stateRoot"];
    const pathInfo = blockView.type.getPathInfo(path);
    const proofObj = createProof(blockView.node, {
      type: ProofType.single,
      gindex: pathInfo.gindex,
    }) as any;
    const proof = proofObj.witnesses.map((w: Uint8Array) => bytesToHex(w));
    const leaf = bytesToHex(proofObj.leaf as Uint8Array);
    return { proof, leaf };
  }

  private async getStorageProofs(opts: GetStorageProofsInput) {
    console.log("getStorageProofs");
    const { dstChain, l1BlockNumber, l2Block, l2Slot, nodeIndex } = opts;
    const { sepolia: sepoliaClient } = clients;
    const dstClient = clients[dstChain];

    const calls = [
      sepoliaClient.getProof(
        this.buildL1Proof(dstChain, l1BlockNumber, nodeIndex)
      ),
      dstClient.getProof({
        // address: addresses[dstChain].opSepoliaWethAddr,
        address: addresses[dstChain].rip7755VerifierContractAddr,
        storageKeys: [l2Slot],
        blockNumber: l2Block.number,
      }),
    ];

    if (dstChain === SupportedChains.OptimismSepolia) {
      calls.push(
        dstClient.getProof({
          address: addresses.optimismSepolia.l2MessagePasserAddr,
          storageKeys: [],
          blockNumber: l2Block.number,
        })
      );
    }

    const storageProofs = await Promise.all(calls);

    const [storageProof, l2StorageProof, l2MessagePasserStorageProof] =
      storageProofs;
    return { storageProof, l2StorageProof, l2MessagePasserStorageProof };
  }

  private buildL1Proof(
    dstChain: SupportedChains,
    l1BlockNumber: bigint,
    nodeIndex: bigint | null
  ) {
    let address = addresses.sepolia.anchorStateRegistryAddr;
    let storageKeys = [constants.slots.anchorStateRegistrySlot];

    if (dstChain === SupportedChains.ArbitrumSepolia) {
      if (!nodeIndex) {
        throw new Error("Node index is required for Arbitrum proofs");
      }
      address = addresses.sepolia.arbRollupAddr;
      const slot = 118n;
      const offset = 2n; // confirmData is offset by 2 slots in Node struct
      const derivedSlotStart = keccak256(
        encodeAbiParameters(
          [{ type: "uint64" }, { type: "uint256" }],
          [nodeIndex, slot]
        )
      );
      const derivedSlot = toHex(BigInt(derivedSlotStart) + offset);
      storageKeys = [derivedSlot];
    }

    return { address, storageKeys, blockNumber: l1BlockNumber };
  }

  private deriveRIP7755VerifierStorageSlot(requestHash: Address): Address {
    console.log("deriveRIP7755VerifierStorageSlot");
    return keccak256(
      encodeAbiParameters(
        [{ type: "bytes32" }, { type: "uint256" }],
        [requestHash, BigInt(constants.slots.fulfillmentInfoSlot)]
      )
    );
  }

  private async storeProofObj(
    proofs: Proofs,
    l2Block: Block,
    beaconData: GetBeaconRootAndL2TimestampReturnType,
    stateRootInclusion: StateRootProofReturnType,
    sendRoot: Address | null,
    nodeIndex: bigint | null
  ): Promise<any> {
    console.log("storeProofObj");
    const proofObj: any = {
      l2StateRoot: l2Block.stateRoot,
      l2BlockHash: l2Block.hash,
      stateProofParams: {
        beaconRoot: beaconData.beaconRoot,
        beaconOracleTimestamp: toHex(beaconData.timestampForL2BeaconOracle, {
          size: 32,
        }),
        executionStateRoot: stateRootInclusion.leaf,
        stateRootProof: stateRootInclusion.proof,
      },
      dstL2StateRootProofParams: {
        storageKey: proofs.storageProof.storageProof[0].key,
        storageValue: toHex(proofs.storageProof.storageProof[0].value),
        accountProof: proofs.storageProof.accountProof,
        storageProof: proofs.storageProof.storageProof[0].proof,
      },
      dstL2AccountProofParams: {
        storageKey: proofs.l2StorageProof.storageProof[0].key,
        storageValue: toHex(proofs.l2StorageProof.storageProof[0].value),
        accountProof: proofs.l2StorageProof.accountProof,
        storageProof: proofs.l2StorageProof.storageProof[0].proof,
      },
    };

    if (proofs.l2MessagePasserStorageProof) {
      proofObj["l2MessagePasserStorageRoot"] =
        proofs.l2MessagePasserStorageProof.storageHash;
    }

    if (config.dstChain === SupportedChains.ArbitrumSepolia) {
      if (!sendRoot) {
        throw new Error("Send Root is required for Arbitrum proofs");
      }
      if (!nodeIndex) {
        throw new Error("Node index is required for Arbitrum proofs");
      }
      proofObj["sendRoot"] = sendRoot;
      if (!l2Block.number) {
        throw new Error("L2Block missing number");
      }
      if (!l2Block.baseFeePerGas) {
        throw new Error("L2Block missing baseFeePerGas");
      }
      if (!l2Block.logsBloom) {
        throw new Error("L2Block missing logsBloom");
      }
      if (!l2Block.nonce) {
        throw new Error("L2Block missing nonce");
      }
      const blockArray = [
        l2Block.parentHash,
        l2Block.sha3Uncles,
        l2Block.miner,
        l2Block.stateRoot,
        l2Block.transactionsRoot,
        l2Block.receiptsRoot,
        l2Block.logsBloom,
        toHex(l2Block.difficulty),
        toHex(l2Block.number),
        toHex(l2Block.gasLimit),
        toHex(l2Block.gasUsed),
        toHex(l2Block.timestamp),
        l2Block.extraData,
        l2Block.mixHash,
        l2Block.nonce,
        toHex(l2Block.baseFeePerGas),
      ];

      if (keccak256(toRlp(blockArray)) !== l2Block.hash) {
        throw new Error("Blockhash mismatch");
      }

      proofObj["encodedBlockArray"] = toRlp(blockArray);
      proofObj["nodeIndex"] = toHex(nodeIndex, { size: 32 });

      delete proofObj.l2StateRoot;
      delete proofObj.l2BlockHash;
    }

    return proofObj;
  }
}
