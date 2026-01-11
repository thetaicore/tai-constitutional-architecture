import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("--------------------------------------------------");
  console.log("Deploying TaiAIContract");
  console.log("Deployer:", deployer.address);

  // 🔧 CONFIG
  const DAO_ADDRESS = deployer.address; // temporary DAO (can be TaiDAO later)
  const BASE_RESONANCE = 70;

  const TaiAI = await ethers.getContractFactory("TaiAIContract");
  const taiAI = await TaiAI.deploy(DAO_ADDRESS, BASE_RESONANCE);

  // ⏳ ethers v5 style
  await taiAI.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ TaiAIContract deployed successfully");
  console.log("📍 Address:", taiAI.address);
  console.log("🧠 DAO:", DAO_ADDRESS);
  console.log("🔮 Base Resonance:", BASE_RESONANCE);
  console.log("--------------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

