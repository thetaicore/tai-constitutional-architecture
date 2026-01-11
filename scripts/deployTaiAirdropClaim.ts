import { ethers } from "hardhat";

async function main() {
  const TAI_PEG_ORACLE = process.env.TAI_PEG_ORACLE_ADDRESS;
  const TAI_COIN = process.env.TAI_COIN_ADDRESS;
  const TAI_AI = process.env.TAI_AI_CONTRACT_ADDRESS;
  const FORWARDER = process.env.ERC2771_FORWARDER_ADDRESS;

  if (!TAI_PEG_ORACLE) throw new Error("TAI_PEG_ORACLE_ADDRESS not set in .env");
  if (!TAI_COIN) throw new Error("TAI_COIN_ADDRESS not set in .env");
  if (!TAI_AI) throw new Error("TAI_AI_CONTRACT_ADDRESS not set in .env");
  if (!FORWARDER) throw new Error("ERC2771_FORWARDER_ADDRESS not set in .env");

  console.log("--------------------------------------------------");
  console.log("🚀 Deploying TaiAirdropClaim");
  console.log("Oracle:", TAI_PEG_ORACLE);
  console.log("TaiCoin:", TAI_COIN);
  console.log("TAI AI:", TAI_AI);
  console.log("Forwarder:", FORWARDER);
  console.log("--------------------------------------------------");

  // Connect to oracle
  const oracle = await ethers.getContractAt("TaiPegOracleInstance", TAI_PEG_ORACLE);
  const merkleRoot: string = await oracle.lastUnit(); // <-- adjust if needed

  console.log("✅ Using merkle root from oracle:", merkleRoot);

  const Factory = await ethers.getContractFactory("TaiAirdropClaim");
  const contract = await Factory.deploy(TAI_COIN, merkleRoot, TAI_AI, FORWARDER);

  // 🔹 FIXED HERE: ethers v5 requires deployed()
  await contract.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ TaiAirdropClaim deployed at:", contract.address);

  // Append to .env
  const fs = require("fs");
  fs.appendFileSync(
    "../.env",
    `\n# ===== TaiAirdropClaim =====\nTAI_AIRDROP_CLAIM_ADDRESS=${contract.address}\n`
  );

  console.log("✅ Address appended to .env");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});

