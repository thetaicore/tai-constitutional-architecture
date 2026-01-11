const { ethers, network } = require("hardhat");
require("dotenv").config({ path: "../.env" });

function clean(addr, name) {
  if (!addr) throw new Error(`Missing ${name}`);
  const a = addr.trim().toLowerCase();
  if (!/^0x[a-f0-9]{40}$/.test(a)) throw new Error(`Invalid ${name}`);
  return a;
}

async function main() {
  if (network.name !== "mainnet") {
    throw new Error("❌ This deployment is MAINNET ONLY");
  }

  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying TaiBridgeVaultLZ");
  console.log("Deployer:", deployer.address);

  const LZ_ENDPOINT = clean(
    process.env.LZ_ENDPOINT_MAINNET,
    "LZ_ENDPOINT_MAINNET"
  );

  const FORWARDER = clean(
    process.env.ERC2771_FORWARDER_ADDRESS,
    "ERC2771_FORWARDER_ADDRESS"
  );

  const FINAL_GOVERNOR = clean(
    process.env.TAI_GOVERNOR_ADDRESS,
    "TAI_GOVERNOR_ADDRESS"
  );

  const Factory = await ethers.getContractFactory("TaiBridgeVaultLZ");

  // 1️⃣ DEPLOY
  const contract = await Factory.deploy(
    LZ_ENDPOINT,
    FORWARDER,
    { gasLimit: 3_000_000 }
  );

  await contract.deployed();

  console.log("✅ TaiBridgeVaultLZ deployed at:", contract.address);

  // 2️⃣ INITIALIZE (THIS IS THE KEY DIFFERENCE)
  console.log("🔐 Initializing & transferring governance…");

  const tx = await contract.initialize(FINAL_GOVERNOR, {
    gasLimit: 500_000
  });

  await tx.wait();

  console.log("✅ Initialization complete");
  console.log("👑 Governor set to:", FINAL_GOVERNOR);
}

main().catch((err) => {
  console.error("❌ Deployment failed:");
  console.error(err);
  process.exit(1);
});

