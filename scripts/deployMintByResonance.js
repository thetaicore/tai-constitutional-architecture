require("dotenv").config({ path: "../.env" });
const { ethers } = require("hardhat");

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`❌ Missing env var: ${name}`);
  return v;
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Pull mainnet addresses from environment
  const TAI_COIN = requireEnv("TAI_COIN");           // Already deployed TaiCoin
  const DAO_ADDR = requireEnv("DAO_ADDRESS");       // DAO mainnet address
  const AI_CONTRACT = requireEnv("TAI_AI_CONTRACT_ADDRESS"); // Pre-deployed AI

  console.log("TaiCoin:", TAI_COIN);
  console.log("DAO:", DAO_ADDR);
  console.log("AI Contract:", AI_CONTRACT);

  // Deploy MintByResonance
  const MintByResonance = await ethers.getContractFactory("TaiMintByResonance");
  const mintByResonance = await MintByResonance.deploy(
    TAI_COIN,
    DAO_ADDR,
    AI_CONTRACT
  );

  await mintByResonance.deployed();
  console.log("✅ MintByResonance deployed at:", mintByResonance.address);

  // Export for future environment ingestion
  console.log(`\n📌 EXPORT THIS:\nMINT_BY_RESONANCE_ADDRESS=${mintByResonance.address}`);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});

