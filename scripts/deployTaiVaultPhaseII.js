require("dotenv").config({ path: "./.env" });
const { ethers, network } = require("hardhat");

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`❌ Missing env var: ${name}`);
  return v.trim();
}

async function main() {
  console.log("--------------------------------------------------");
  console.log("🚀 Deploying TaiVaultPhaseII");
  console.log("🌐 Network:", network.name);
  console.log("--------------------------------------------------");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // ===== Required environment variables =====
  const FORWARDER   = requireEnv("ERC2771_FORWARDER_ADDRESS");
  const TAI_COIN    = requireEnv("TAI_COIN");
  const TAI_AI      = requireEnv("TAI_AI_CONTRACT_ADDRESS");
  const LZ_ENDPOINT = requireEnv("LAYER_ZERO_ENDPOINT");
  const DAO         = requireEnv("DAO_ADDRESS");

  // Gas relayer defaults to deployer (safe bootstrap)
  const GAS_RELAYER = deployer.address;

  // ===== Deploy =====
  const Factory = await ethers.getContractFactory("TaiVaultPhaseII", deployer);

  const vault = await Factory.deploy(
    FORWARDER,
    TAI_COIN,
    GAS_RELAYER,
    LZ_ENDPOINT,
    TAI_AI
  );

  // ethers v5 deployment wait
  await vault.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ TaiVaultPhaseII deployed successfully");
  console.log("📍 Address:", vault.address);
  console.log("--------------------------------------------------");

  // ===== Ownership transfer (if needed) =====
  if (DAO.toLowerCase() !== deployer.address.toLowerCase()) {
    const tx = await vault.transferOwnership(DAO);
    await tx.wait();
    console.log("🔑 Ownership transferred to DAO:", DAO);
  }

  console.log("🎉 Deployment complete");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Deployment failed:", err);
    process.exit(1);
  });

