import {
  arbitrumSepolia,
  baseSepolia,
  optimismSepolia,
  sepolia,
} from "viem/chains";
import { createPublicClient, http } from "viem";

import { Provers, type ChainConfig } from "../common/types/chain";
import { chainA } from "../common/chains/chainA";
import { chainB } from "../common/chains/chainB";
import { mockL1 } from "../common/chains/mockL1";

export default {
  // Arbitrum Sepolia
  421614: {
    chainId: 421614,
    outboxContracts: {
      OPStack: "0x3eD4f0892020a9C57586c33554032be00fE379E4",
    },
    rpcUrl:
      process.env.ARBITRUM_SEPOLIA_RPC ||
      arbitrumSepolia.rpcUrls.default.http[0],
    l2Oracle: "0xd80810638dbDF9081b72C1B33c65375e807281C8",
    l2OracleStorageKey:
      "0x0000000000000000000000000000000000000000000000000000000000000076",
    contracts: {
      // inbox: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874", // mock verifier address
      inbox: "0xCdadDE9005974Fbd3385184d1C1C34ef455Cb2Be",
    },
    publicClient: createPublicClient({
      chain: arbitrumSepolia,
      transport: http(process.env.ARBITRUM_SEPOLIA_RPC),
    }),
    targetProver: Provers.Arbitrum,
  },
  // Base Sepolia
  84532: {
    chainId: 84532,
    outboxContracts: {
      Arbitrum: "0xcDdCD048d3AbdE4c917391f65fE296B64841619C",
      OPStack: "0x558D42DFD77B6E0aD643F63C23aaba426359cd75",
    },
    rpcUrl: process.env.BASE_SEPOLIA_RPC || baseSepolia.rpcUrls.default.http[0],
    l2Oracle: "0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xFce77110df39c54681a0769EB515cCE862d074d9",
    },
    publicClient: createPublicClient({
      chain: baseSepolia,
      transport: http(),
    }),
    targetProver: Provers.OPStack,
  },
  // Optimism Sepolia
  11155420: {
    chainId: 11155420,
    outboxContracts: {
      Arbitrum: "0xD7a5A114A07cC4B5ebd9C5e1cD1136a99fFA3d68",
      OPStack: "0xB482b292878FDe64691d028A2237B34e91c7c7ea",
    },
    rpcUrl:
      process.env.OPTIMISM_SEPOLIA_RPC ||
      optimismSepolia.rpcUrls.default.http[0],
    l2Oracle: "0x218CD9489199F321E1177b56385d333c5B598629",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      l2MessagePasser: "0x4200000000000000000000000000000000000016",
      inbox: "0xaC60fCC226899F14016d14CfCC955598D4cbe10F",
    },
    publicClient: createPublicClient({
      chain: optimismSepolia,
      transport: http(),
    }),
    targetProver: Provers.OPStack,
  },
  // Sepolia
  11155111: {
    chainId: 11155111,
    outboxContracts: {},
    rpcUrl: process.env.SEPOLIA_RPC || sepolia.rpcUrls.default.http[0],
    l2Oracle: "0x",
    l2OracleStorageKey: "0x",
    contracts: {},
    publicClient: createPublicClient({
      chain: sepolia,
      transport: http(process.env.SEPOLIA_RPC),
    }),
    targetProver: Provers.None,
  },
  // Mock Base
  111111: {
    chainId: 111111,
    outboxContracts: {
      Arbitrum: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      OPStack: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    },
    rpcUrl: "http://localhost:8546",
    l2Oracle: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    },
    publicClient: createPublicClient({
      chain: chainA,
      transport: http(),
    }),
    targetProver: Provers.OPStack,
  },
  // Mock Optimism
  111112: {
    chainId: 111112,
    outboxContracts: {
      Arbitrum: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      OPStack: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    },
    rpcUrl: "http://localhost:8547",
    l2Oracle: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
      l2MessagePasser: "0x4200000000000000000000000000000000000016",
    },
    publicClient: createPublicClient({
      chain: chainB,
      transport: http(),
    }),
    targetProver: Provers.OPStack,
  },
  // Mock L1
  31337: {
    chainId: 31337,
    outboxContracts: {},
    rpcUrl: "http://localhost:8545",
    l2Oracle: "0x",
    l2OracleStorageKey: "0x",
    contracts: {},
    publicClient: createPublicClient({
      chain: mockL1,
      transport: http(),
    }),
    targetProver: Provers.None,
  },
} as Record<number, ChainConfig>;
