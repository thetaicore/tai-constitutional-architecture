require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

// Utility: Fetch environment variable or throw if missing
function getEnvVar(label) {
  const value = process.env[label];
  if (!value || value === "") throw new Error(`❌ Missing environment variable: ${label}`);
  return value.trim();
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying TaiDAO from:", deployer.address);

  // -----------------------------
  // Load mainnet environment variables
  // -----------------------------
  const TAI_TOKEN = getEnvVar("TAI_COIN");                       // TaiCoin ERC20
  const MINTING_RATE = 1000;                                     // Default or system-specified
  const COLLATERAL_RATIO = 5000;                                  // Default or system-specified
  const CROSS_CHAIN_ENDPOINT = getEnvVar("LZ_ENDPOINT_MAINNET"); // LayerZero Mainnet
  const GAS_RELAYER = deployer.address;                           // Temporary: deployer as gas relayer
  const AI_CONTRACT = getEnvVar("TAI_AI_CONTRACT_ADDRESS");      // TaiAIContract mainnet
  const DAO_ADDRESS = getEnvVar("DAO_ADDRESS");                  // Mainnet DAO EOA
  const FORWARDER = getEnvVar("TRUSTED_FORWARDER");             // ERC2771 Forwarder

  // -----------------------------
  // Deploy TaiDAO contract
  // -----------------------------
  const TaiDAOFactory = await ethers.getContractFactory("TaiDAO", deployer);
  const taiDAO = await TaiDAOFactory.deploy(
    TAI_TOKEN,
    MINTING_RATE,
    COLLATERAL_RATIO,
    CROSS_CHAIN_ENDPOINT,
    GAS_RELAYER,
    AI_CONTRACT,
    DAO_ADDRESS,
    FORWARDER
  );

  // Wait for deployment confirmation
  await taiDAO.deployed();

  const taiDAOAddress = taiDAO.target || taiDAO.address;
  console.log(`✅ TaiDAO deployed at: ${taiDAOAddress}`);

  // -----------------------------
  // Append to .env exactly like your previous deployments
  // -----------------------------
  const ENV_APPEND = `\nTAI_DAO_ADDRESS=${taiDAOAddress}\n`;
  fs.appendFileSync("../.env", ENV_APPEND);
  console.log("✅ Address appended to .env for future architecture reference");

  // -----------------------------
  // Mainnet integration check
  // -----------------------------
  console.log("\n--- Mainnet Integration Check ---");
  console.log("TAI_COIN:", TAI_TOKEN);
  console.log("TAI_AI_CONTRACT:", AI_CONTRACT);
  console.log("DAO_ADDRESS:", DAO_ADDRESS);
  console.log("DEPLOYED TAI_DAO:", taiDAOAddress);
  console.log("---------------------------------");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Deployment failed:", err);
    process.exit(1);
  });

