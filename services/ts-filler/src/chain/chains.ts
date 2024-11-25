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
    proverContracts: {
      OPStackProver: "0x062fBdCfd17A0346D2A9d89FE233bbAdBd1DC14C",
    },
    rpcUrl:
      process.env.ARBITRUM_SEPOLIA_RPC ||
      arbitrumSepolia.rpcUrls.default.http[0],
    l2Oracle: "0xd80810638dbDF9081b72C1B33c65375e807281C8",
    l2OracleStorageKey:
      "0x0000000000000000000000000000000000000000000000000000000000000076",
    contracts: {
      // inbox: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874", // mock verifier address
      inbox: "0xeE962eD1671F655a806cB22623eEA8A7cCc233bC",
      outbox: "0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2",
    },
    publicClient: createPublicClient({
      chain: arbitrumSepolia,
      transport: http(process.env.ARBITRUM_SEPOLIA_RPC),
    }),
    targetProver: Provers.ArbitrumProver,
  },
  // Base Sepolia
  84532: {
    chainId: 84532,
    proverContracts: {
      ArbitrumProver: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
      OPStackProver: "0x562879614C9Db8Da9379be1D5B52BAEcDD456d78",
    },
    rpcUrl: process.env.BASE_SEPOLIA_RPC || baseSepolia.rpcUrls.default.http[0],
    l2Oracle: "0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xB482b292878FDe64691d028A2237B34e91c7c7ea",
      outbox: "0xD7a5A114A07cC4B5ebd9C5e1cD1136a99fFA3d68",
    },
    publicClient: createPublicClient({
      chain: baseSepolia,
      transport: http(),
    }),
    targetProver: Provers.OPStackProver,
  },
  // Optimism Sepolia
  11155420: {
    chainId: 11155420,
    proverContracts: {},
    rpcUrl:
      process.env.OPTIMISM_SEPOLIA_RPC ||
      optimismSepolia.rpcUrls.default.http[0],
    l2Oracle: "0x218CD9489199F321E1177b56385d333c5B598629",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      l2MessagePasser: "0x4200000000000000000000000000000000000016",
      inbox: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
    },
    publicClient: createPublicClient({
      chain: optimismSepolia,
      transport: http(),
    }),
    targetProver: Provers.OPStackProver,
  },
  // Sepolia
  11155111: {
    chainId: 11155111,
    proverContracts: {},
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
    proverContracts: {
      ArbitrumProver: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      OPStackProver: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    },
    rpcUrl: "http://localhost:8546",
    l2Oracle: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
      // outbox: "0xD7a5A114A07cC4B5ebd9C5e1cD1136a99fFA3d68",
    },
    publicClient: createPublicClient({
      chain: chainA,
      transport: http(),
    }),
    targetProver: Provers.OPStackProver,
  },
  // Mock Optimism
  111112: {
    chainId: 111112,
    proverContracts: {
      ArbitrumProver: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      OPStackProver: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    },
    rpcUrl: "http://localhost:8547",
    l2Oracle: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      inbox: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
      // outbox: "0xD7a5A114A07cC4B5ebd9C5e1cD1136a99fFA3d68",
      l2MessagePasser: "0x4200000000000000000000000000000000000016",
    },
    publicClient: createPublicClient({
      chain: chainB,
      transport: http(),
    }),
    targetProver: Provers.OPStackProver,
  },
  // Mock L1
  31337: {
    chainId: 31337,
    proverContracts: {},
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
