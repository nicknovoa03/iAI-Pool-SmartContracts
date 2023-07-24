import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from 'dotenv';
dotenv.config();

const BscPrivateKey = process.env.BSC_PRIVATE_KEY!
const EthPrivateKey = process.env.ETH_PRIVATE_KEY!
const EthTestPrivateKey = process.env.ETH_TEST_PRIVATE_KEY!
const EtherscanApiKey = process.env.ETHERSCAN_API_KEY!

const BscProvider = "https://bsc-dataseed.binance.org/"
const EthProvider = "https://mainnet.infura.io/v3/" + process.env.INFURA_API_KEY
const BscTestnetProvider = "https://data-seed-prebsc-1-s1.binance.org:8545"
const EthTestnetProvider = "https://sepolia.infura.io/v3/" + process.env.INFURA_API_KEY

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  etherscan: {
    apiKey: EtherscanApiKey
  },
  networks: {
    bsc: {
      url: BscProvider,
      accounts: [BscPrivateKey],
    },
    sepolia: {
      url: EthTestnetProvider,
      accounts: [EthTestPrivateKey],
    },
    mainnet: {
      url: EthProvider,
      accounts: [EthPrivateKey]
    }
  }
};

export default config;
