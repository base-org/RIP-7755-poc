import {
  bytesToHex,
  encodeAbiParameters,
  keccak256,
  toHex,
  toRlp,
  type Address,
  type Block,
  type Hex,
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
  type Assertion,
  type GetBeaconRootAndL2TimestampReturnType,
} from "../common/types/chain";
import type {
  ArbitrumProofType,
  HashiProofType,
  OPStackProofType,
  ProofType,
} from "../common/types/proof";
import deriveBeaconRoot from "../common/utils/deriveBeaconRoot";

export default class ProverService {
  private usingHashi: boolean;

  constructor(
    private readonly activeChains: ActiveChains,
    private readonly chainService: ChainService,
    private readonly isDevnet = false
  ) {
    this.usingHashi =
      !this.activeChains.src.exposesL1State ||
      !this.activeChains.dst.sharesStateWithL1;
  }

  async generateProof(requestHash: Address): Promise<ProofType> {
    const { proof } = await this.generateProofWithL2Block(requestHash);
    return proof;
  }

  async generateProofWithL2Block(
    requestHash: Address,
    timestampCutoff = 0
  ): Promise<{ proof: ProofType; l2Block: Block }> {
    let beaconData: GetBeaconRootAndL2TimestampReturnType | undefined;
    let l1BlockNumber: bigint | undefined;
    let stateRootInclusion: StateRootProofReturnType | undefined;

    if (!this.usingHashi) {
      if (this.isDevnet) {
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
    }

    const { l2Block, parentAssertionHash, afterInboxBatchAcc, assertion } =
      await this.chainService.getL2Block(l1BlockNumber);
    const l2Slot = this.deriveRIP7755VerifierStorageSlot(requestHash);

    if (timestampCutoff > l2Block.timestamp) {
      throw new Error("L2 block timestamp is too old");
    }

    const storageProofOpts = {
      l1BlockNumber,
      l2Block,
      l2Slot,
      parentAssertionHash,
      afterInboxBatchAcc,
      assertion,
    };
    const storageProofs = await this.getStorageProofs(storageProofOpts);

    const proof = this.storeProofObj(
      storageProofs,
      l2Block,
      beaconData,
      stateRootInclusion,
      assertion,
      parentAssertionHash,
      afterInboxBatchAcc
    );

    return { proof, l2Block };
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
    const {
      l1BlockNumber,
      l2Block,
      l2Slot,
      parentAssertionHash,
      afterInboxBatchAcc,
      assertion,
    } = opts;
    const dstConfig = this.activeChains.dst;

    const calls = [
      dstConfig.publicClient.getProof({
        address: dstConfig.contracts.inbox,
        storageKeys: [l2Slot],
        blockNumber: l2Block.number,
      }),
    ];

    if (!this.usingHashi) {
      if (!l1BlockNumber) {
        throw new Error("L1 block number is required for non-Hashi proofs");
      }

      calls.push(
        this.activeChains.l1.publicClient.getProof(
          this.buildL1Proof(
            l1BlockNumber,
            parentAssertionHash,
            afterInboxBatchAcc,
            assertion
          )
        )
      );

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
    }

    const storageProofs = await Promise.all(calls);

    const [l2StorageProof, storageProof, l2MessagePasserStorageProof] =
      storageProofs;
    return { storageProof, l2StorageProof, l2MessagePasserStorageProof };
  }

  private buildL1Proof(
    l1BlockNumber: bigint,
    parentAssertionHash?: Hex,
    afterInboxBatchAcc?: Hex,
    assertion?: Assertion
  ): { address: Address; storageKeys: Address[]; blockNumber: bigint } {
    const address = this.activeChains.dst.l2Oracle;
    let storageKeys = [constants.slots.anchorStateRegistrySlot];

    if (this.activeChains.dst.chainId === SupportedChains.ArbitrumSepolia) {
      if (!parentAssertionHash) {
        throw new Error(
          "Parent assertion hash is required for Arbitrum proofs"
        );
      }
      if (!assertion) {
        throw new Error("Assertion is required for Arbitrum proofs");
      }
      if (!afterInboxBatchAcc) {
        throw new Error(
          "After inbox batch acc is required for Arbitrum proofs"
        );
      }

      const afterStateHash = keccak256(
        encodeAbiParameters(
          [
            {
              components: [
                {
                  components: [
                    {
                      internalType: "bytes32[2]",
                      name: "bytes32Vals",
                      type: "bytes32[2]",
                    },
                    {
                      internalType: "uint64[2]",
                      name: "u64Vals",
                      type: "uint64[2]",
                    },
                  ],
                  internalType: "struct GlobalState",
                  name: "globalState",
                  type: "tuple",
                },
                {
                  internalType: "enum MachineStatus",
                  name: "machineStatus",
                  type: "uint8",
                },
                {
                  internalType: "bytes32",
                  name: "endHistoryRoot",
                  type: "bytes32",
                },
              ],
              internalType: "struct AssertionState",
              name: "beforeState",
              type: "tuple",
            },
          ],
          [assertion]
        )
      );
      const newAssertionHash = keccak256(
        encodeAbiParameters(
          [{ type: "bytes32" }, { type: "bytes32" }, { type: "bytes32" }],
          [parentAssertionHash, afterStateHash, afterInboxBatchAcc]
        )
      );
      const slot = 117n;
      const derivedSlot = keccak256(
        encodeAbiParameters(
          [{ type: "bytes32" }, { type: "uint256" }],
          [newAssertionHash, slot]
        )
      );
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
    beaconData?: GetBeaconRootAndL2TimestampReturnType,
    stateRootInclusion?: StateRootProofReturnType,
    assertion?: Assertion,
    parentAssertionHash?: Hex,
    afterInboxBatchAcc?: Hex
  ): ProofType {
    console.log("storeProofObj");

    if (this.usingHashi) {
      return this.buildHashiProof(proofs, l2Block);
    }

    if (!beaconData) {
      throw new Error("Beacon data is required for non-Hashi proofs");
    }
    if (!stateRootInclusion) {
      throw new Error("State root inclusion is required for non-Hashi proofs");
    }

    switch (this.activeChains.dst.chainId) {
      case SupportedChains.ArbitrumSepolia:
        if (!assertion) {
          throw new Error("Assertion is required for Arbitrum proofs");
        }
        if (!parentAssertionHash) {
          throw new Error(
            "Parent assertion hash is required for Arbitrum proofs"
          );
        }
        if (!afterInboxBatchAcc) {
          throw new Error(
            "After inbox batch acc is required for Arbitrum proofs"
          );
        }
        return this.buildArbitrumProof(
          proofs,
          l2Block,
          beaconData,
          stateRootInclusion,
          assertion,
          parentAssertionHash,
          afterInboxBatchAcc
        );
      case SupportedChains.OptimismSepolia:
        return this.buildOPStackProof(
          proofs,
          l2Block,
          beaconData,
          stateRootInclusion
        );
      default:
        throw new Error("Unsupported chain");
    }
  }

  private buildArbitrumProof(
    proofs: Proofs,
    l2Block: Block,
    beaconData: GetBeaconRootAndL2TimestampReturnType,
    stateRootInclusion: StateRootProofReturnType,
    assertion: Assertion,
    parentAssertionHash: Hex,
    afterInboxBatchAcc: Hex
  ): ArbitrumProofType {
    if (!proofs.storageProof) {
      throw new Error("Storage proof is required for Arbitrum proofs");
    }

    if (proofs.storageProof.storageProof[0].value === 0n) {
      throw new Error("Storage proof value is 0");
    }
    if (proofs.l2StorageProof.storageProof[0].value === 0n) {
      throw new Error("L2 storage proof value is 0");
    }

    return {
      stateProofParams: {
        beaconRoot: beaconData.beaconRoot,
        beaconOracleTimestamp: beaconData.timestampForL2BeaconOracle,
        executionStateRoot: stateRootInclusion.leaf,
        stateRootProof: stateRootInclusion.proof,
      },
      dstL2StateRootProofParams: {
        storageKey: proofs.storageProof.storageProof[0].key,
        storageValue: this.convertToHex(
          proofs.storageProof.storageProof[0].value
        ),
        accountProof: proofs.storageProof.accountProof,
        storageProof: proofs.storageProof.storageProof[0].proof,
      },
      dstL2AccountProofParams: {
        storageKey: proofs.l2StorageProof.storageProof[0].key,
        storageValue: this.convertToHex(
          proofs.l2StorageProof.storageProof[0].value
        ),
        accountProof: proofs.l2StorageProof.accountProof,
        storageProof: proofs.l2StorageProof.storageProof[0].proof,
      },
      encodedBlockArray: this.getEncodedBlockArray(l2Block),
      afterState: assertion,
      prevAssertionHash: parentAssertionHash,
      sequencerBatchAcc: afterInboxBatchAcc,
    };
  }

  private buildOPStackProof(
    proofs: Proofs,
    l2Block: Block,
    beaconData: GetBeaconRootAndL2TimestampReturnType,
    stateRootInclusion: StateRootProofReturnType
  ): OPStackProofType {
    if (!proofs.l2MessagePasserStorageProof) {
      throw new Error(
        "L2 message passer storage proof is required for OPStack proofs"
      );
    }
    if (!proofs.storageProof) {
      throw new Error("Storage proof is required for OPStack proofs");
    }
    if (proofs.storageProof.storageProof[0].value === 0n) {
      throw new Error("Storage proof value is 0");
    }
    if (proofs.l2StorageProof.storageProof[0].value === 0n) {
      throw new Error("L2 storage proof value is 0");
    }

    return {
      l2MessagePasserStorageRoot:
        proofs.l2MessagePasserStorageProof.storageHash,
      encodedBlockArray: this.getEncodedBlockArray(l2Block),
      stateProofParams: {
        beaconRoot: beaconData.beaconRoot,
        beaconOracleTimestamp: beaconData.timestampForL2BeaconOracle,
        executionStateRoot: stateRootInclusion.leaf,
        stateRootProof: stateRootInclusion.proof,
      },
      dstL2StateRootProofParams: {
        storageKey: proofs.storageProof.storageProof[0].key,
        storageValue: this.convertToHex(
          proofs.storageProof.storageProof[0].value
        ),
        accountProof: proofs.storageProof.accountProof,
        storageProof: proofs.storageProof.storageProof[0].proof,
      },
      dstL2AccountProofParams: {
        storageKey: proofs.l2StorageProof.storageProof[0].key,
        storageValue: this.convertToHex(
          proofs.l2StorageProof.storageProof[0].value
        ),
        accountProof: proofs.l2StorageProof.accountProof,
        storageProof: proofs.l2StorageProof.storageProof[0].proof,
      },
    };
  }

  private buildHashiProof(proofs: Proofs, l2Block: Block): HashiProofType {
    if (proofs.l2StorageProof.storageProof[0].value === 0n) {
      throw new Error("L2 storage proof value is 0");
    }

    return {
      rlpEncodedBlockHeader: this.getEncodedBlockArray(l2Block),
      dstAccountProofParams: {
        storageKey: proofs.l2StorageProof.storageProof[0].key,
        storageValue: this.convertToHex(
          proofs.l2StorageProof.storageProof[0].value
        ),
        accountProof: proofs.l2StorageProof.accountProof,
        storageProof: proofs.l2StorageProof.storageProof[0].proof,
      },
    };
  }

  private getEncodedBlockArray(l2Block: Block): Hex {
    const blockArray = this.buildBlockArray(l2Block);
    const encodedBlockArray = toRlp(blockArray);

    if (keccak256(encodedBlockArray) !== l2Block.hash) {
      throw new Error("Blockhash mismatch");
    }

    return encodedBlockArray;
  }

  private buildBlockArray(l2Block: any): Hex[] {
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

  private convertToHex(value: bigint): Hex {
    const tmp = toHex(value);

    if (tmp.length % 2 !== 0) {
      return ("0x0" + tmp.slice(2)) as Hex;
    }

    return tmp;
  }
}
