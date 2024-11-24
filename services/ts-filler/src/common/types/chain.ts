import type { Address, Block, Hex } from "viem";

export type L2Block = Block & { parentBeaconBlockRoot: Hex; number: bigint };

export type GetBeaconRootAndL2TimestampReturnType = {
  beaconRoot: Hex;
  timestampForL2BeaconOracle: bigint;
};

export type DecodedNodeCreatedLog = { args: { assertion: any } };

export type ChainConfig = {
  chainId: number;
  proverContracts: Record<string, Address>;
  rpcUrl: string;
  l2Oracle: Address;
  l2OracleStorageKey: Address;
  publicClient: any;
  contracts: Record<string, Address>;
  targetProver: Provers;
};

export enum SupportedChains {
  ArbitrumSepolia = 421614,
  BaseSepolia = 84532,
  OptimismSepolia = 11155420,
  Sepolia = 11155111,
  MockBase = 111111,
  MockOptimism = 111112,
  MockL1 = 31337,
}

export type ActiveChains = {
  src: ChainConfig;
  l1: ChainConfig;
  dst: ChainConfig;
};

export enum Provers {
  None = "None",
  ArbitrumProver = "ArbitrumProver",
  OPStackProver = "OPStackProver",
}
