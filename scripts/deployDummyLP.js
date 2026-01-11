require("dotenv").config();
const fs = require("fs");
const { ethers, network } = require("hardhat");

// -----------------------------
// Helpers
// -----------------------------
function appendEnv(key, value) {
  fs.appendFileSync(
    "./.env",
    `\n# ------------------------------\n# ${key}\n# ------------------------------\n${key}=${value}\n`
  );
  console.log(`✅ ${key} appended to .env`);
}

// -----------------------------
// Main
// -----------------------------
async function main() {
  console.log("--------------------------------------------------");
  console.log("🚀 Deploying DummyLP (MAINNET)");
  console.log("🌐 Network:", network.name);
  console.log("--------------------------------------------------");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const DummyLPFactory = await ethers.getContractFactory("DummyLP", deployer);
  const dummyLP = await DummyLPFactory.deploy();

  // ✅ ethers v5
  await dummyLP.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ DummyLP deployed successfully");
  console.log("📍 Address:", dummyLP.address);
  console.log("--------------------------------------------------");

  appendEnv("DUMMY_LP_ADDRESS", dummyLP.address);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Deployment failed:", err);
    process.exit(1);
  });

