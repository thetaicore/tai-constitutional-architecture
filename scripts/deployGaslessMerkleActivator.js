require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`❌ Missing env var: ${name}`);
  return v;
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying with account:", deployer.address);

  // Pull mainnet addresses from environment
  const VAULT_ADDRESS = requireEnv("TAI_VAULT_MERKLE_CLAIM");
  const TAI_ADDRESS = requireEnv("TAI_ADDRESS");
  const FORWARDER_ADDRESS = requireEnv("FORWARDER_ADDRESS");

  console.log("Vault:", VAULT_ADDRESS);
  console.log("TAI:", TAI_ADDRESS);
  console.log("Forwarder:", FORWARDER_ADDRESS);

  // Deploy GaslessMerkleActivator
  const ActivatorFactory = await ethers.getContractFactory("GaslessMerkleActivator");
  const activator = await ActivatorFactory.deploy(VAULT_ADDRESS, TAI_ADDRESS, FORWARDER_ADDRESS);

  await activator.deployed();  // ✅ Hardhat-compatible deployment confirmation
  const activatorAddress = activator.address;
  console.log("✅ GaslessMerkleActivator deployed at:", activatorAddress);

  // Export for environment ingestion
  console.log(`\n📌 EXPORT THIS:\nGASLESS_MERKLE_ACTIVATOR_ADDRESS=${activatorAddress}`);

  // Save deployment info locally
  const deployPath = path.resolve("./deployed/GaslessMerkleActivator.json");
  fs.mkdirSync(path.dirname(deployPath), { recursive: true });
  fs.writeFileSync(
    deployPath,
    JSON.stringify({ address: activatorAddress, deployer: deployer.address }, null, 2)
  );
  console.log(`📦 Deployment info saved to ${deployPath}`);
}

main().catch(err => {
  console.error("❌ Deployment failed:", err);
  process.exit(1);
});

