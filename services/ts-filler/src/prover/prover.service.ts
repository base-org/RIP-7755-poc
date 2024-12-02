import {
  bytesToHex,
  encodeAbiParameters,
  keccak256,
  toHex,
  toRlp,
  type Address,
  type Block,
} from "viem";
const { ssz } = await import("@lodestar/types");
const { BeaconBlock } = ssz.deneb;
const { createProof, ProofType } = await import(
  "@chainsafe/persistent-merkle-tree"
);

import type ChainService from "../chain/chain.service";
import constants from "../common/constants";
import type {
  GetStorageProofsInput,
  Proofs,
  StateRootProofReturnType,
} from "../common/types/prover";
import {
  SupportedChains,
  type ActiveChains,
  type GetBeaconRootAndL2TimestampReturnType,
} from "../common/types/chain";
import type {
  ArbitrumProofType,
  OPStackProofType,
} from "../common/types/proof";
import config from "../config";
import deriveBeaconRoot from "../common/utils/deriveBeaconRoot";

export default class ProverService {
  constructor(
    private readonly activeChains: ActiveChains,
    private readonly chainService: ChainService
  ) {}

  async generateProof(
    requestHash: Address
  ): Promise<ArbitrumProofType | OPStackProofType> {
    let beaconData: GetBeaconRootAndL2TimestampReturnType;
    let l1BlockNumber: bigint;
    let stateRootInclusion: StateRootProofReturnType;

    if (config.devnet) {
      const l1Block = await this.chainService.getL1Block();
      l1BlockNumber = l1Block.number as bigint;
      stateRootInclusion = {
        proof: constants.mockL1StateRootProof,
        leaf: l1Block.stateRoot,
      };
      beaconData = {
        beaconRoot: deriveBeaconRoot(l1Block.stateRoot),
        timestampForL2BeaconOracle: l1Block.timestamp,
      };
    } else {
      beaconData = await this.chainService.getBeaconRootAndL2Timestamp();
      const beaconBlock = await this.chainService.getBeaconBlock(
        beaconData.beaconRoot
      );
      stateRootInclusion = this.getExecutionStateRootProof(beaconBlock);
      l1BlockNumber = BigInt(beaconBlock.body.executionPayload.blockNumber);
    }

    const { l2Block, sendRoot, nodeIndex } = await this.chainService.getL2Block(
      l1BlockNumber
    );
    const l2Slot = this.deriveRIP7755VerifierStorageSlot(requestHash);

    const storageProofOpts = {
      l1BlockNumber,
      l2Block,
      l2Slot,
      nodeIndex,
    };
    const storageProofs = await this.getStorageProofs(storageProofOpts);

    return this.storeProofObj(
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

  private async getStorageProofs(opts: GetStorageProofsInput): Promise<Proofs> {
    console.log("getStorageProofs");
    const { l1BlockNumber, l2Block, l2Slot, nodeIndex } = opts;
    const dstConfig = this.activeChains.dst;

    const calls = [
      this.activeChains.l1.publicClient.getProof(
        this.buildL1Proof(l1BlockNumber, nodeIndex)
      ),
      dstConfig.publicClient.getProof({
        address: dstConfig.contracts.inbox,
        storageKeys: [l2Slot],
        blockNumber: l2Block.number,
      }),
    ];

    if (
      dstConfig.chainId === SupportedChains.OptimismSepolia ||
      dstConfig.chainId === SupportedChains.MockOptimism
    ) {
      calls.push(
        dstConfig.publicClient.getProof({
          address: dstConfig.contracts.l2MessagePasser,
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
    l1BlockNumber: bigint,
    nodeIndex?: bigint
  ): { address: Address; storageKeys: Address[]; blockNumber: bigint } {
    const address = this.activeChains.dst.l2Oracle;
    let storageKeys = [constants.slots.anchorStateRegistrySlot];

    if (this.activeChains.dst.chainId === SupportedChains.ArbitrumSepolia) {
      if (!nodeIndex) {
        throw new Error("Node index is required for Arbitrum proofs");
      }
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

  private storeProofObj(
    proofs: Proofs,
    l2Block: Block,
    beaconData: GetBeaconRootAndL2TimestampReturnType,
    stateRootInclusion: StateRootProofReturnType,
    sendRoot?: Address,
    nodeIndex?: bigint
  ): ArbitrumProofType | OPStackProofType {
    console.log("storeProofObj");

    const blockArray = this.buildBlockArray(l2Block);

    if (keccak256(toRlp(blockArray)) !== l2Block.hash) {
      throw new Error("Blockhash mismatch");
    }

    const proofObj: any = {
      encodedBlockArray: toRlp(blockArray),
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

    if (this.activeChains.dst.chainId === SupportedChains.ArbitrumSepolia) {
      if (!sendRoot) {
        throw new Error("Send Root is required for Arbitrum proofs");
      }
      if (!nodeIndex) {
        throw new Error("Node index is required for Arbitrum proofs");
      }
      proofObj["sendRoot"] = sendRoot;
      proofObj["nodeIndex"] = nodeIndex;
    }

    return proofObj;
  }

  private buildBlockArray(l2Block: any): any[] {
    const blockArray = [
      l2Block.parentHash,
      l2Block.sha3Uncles,
      l2Block.miner,
      l2Block.stateRoot,
      l2Block.transactionsRoot,
      l2Block.receiptsRoot,
      l2Block.logsBloom,
      l2Block.difficulty !== 0n ? toHex(l2Block.difficulty) : "",
      l2Block.number !== 0n ? toHex(l2Block.number) : "",
      toHex(l2Block.gasLimit),
      toHex(l2Block.gasUsed),
      toHex(l2Block.timestamp),
      l2Block.extraData,
      l2Block.mixHash,
      l2Block.nonce,
    ];
    const tmp1 = l2Block.baseFeePerGas && l2Block.baseFeePerGas !== 0n;
    const tmp2 = l2Block.withdrawalsRoot && l2Block.withdrawalsRoot !== "0x";
    const tmp3 = l2Block.blobGasUsed && l2Block.blobGasUsed !== 0n;
    const tmp4 = l2Block.excessBlobGas && l2Block.excessBlobGas !== 0n;
    const tmp5 =
      l2Block.parentBeaconBlockRoot && l2Block.parentBeaconBlockRoot !== "0x";
    const tmp6 = l2Block.requestsRoot && l2Block.requestsRoot !== "0x";

    if (tmp1 || tmp2 || tmp3 || tmp4 || tmp5 || tmp6) {
      blockArray.push(tmp1 ? toHex(l2Block.baseFeePerGas) : "");
    }

    if (tmp2 || tmp3 || tmp4 || tmp5 || tmp6) {
      blockArray.push(tmp2 ? l2Block.withdrawalsRoot : "");
    }

    if (tmp3 || tmp4 || tmp5 || tmp6) {
      blockArray.push(tmp3 ? toHex(l2Block.blobGasUsed) : "");
    }

    if (tmp4 || tmp5 || tmp6) {
      blockArray.push(tmp4 ? toHex(l2Block.excessBlobGas) : "");
    }

    if (tmp5 || tmp6) {
      blockArray.push(tmp5 ? l2Block.parentBeaconBlockRoot : "");
    }

    if (tmp6) {
      blockArray.push(l2Block.requestsRoot);
    }

    return blockArray;
  }
}
