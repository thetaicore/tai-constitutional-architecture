require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@typechain/hardhat");

const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY || "";
const GOVERNOR_PRIVATE_KEY = process.env.GOVERNOR_PRIVATE_KEY || "";
const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

// Construct RPC URLs dynamically
const MAINNET_RPC_URL = `https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`;
const SEPOLIA_RPC_URL = `https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}`;

console.log("MAINNET_RPC_URL:", MAINNET_RPC_URL);
console.log("SEPOLIA_RPC_URL:", SEPOLIA_RPC_URL);

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: { chainId: 31337, gasPrice: 20000000000, timeout: 2000000 },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [DEPLOYER_PRIVATE_KEY, GOVERNOR_PRIVATE_KEY].filter(Boolean),
      chainId: 11155111,
      gasPrice: "auto",
      timeout: 2000000,
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: [DEPLOYER_PRIVATE_KEY, GOVERNOR_PRIVATE_KEY].filter(Boolean),
      chainId: 1,
      gasPrice: "auto",
      timeout: 2000000,
    },
  },
  etherscan: { apiKey: ETHERSCAN_API_KEY },
  solidity: { compilers: [{ version: "0.8.24", settings: { optimizer: { enabled: true, runs: 200 } } }] },
  paths: { sources: "./contracts", tests: "./test", cache: "./cache", artifacts: "./artifacts" },
  typechain: { outDir: "typechain", target: "ethers-v6" },
};

