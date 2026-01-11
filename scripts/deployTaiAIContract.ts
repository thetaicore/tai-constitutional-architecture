import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const balance = await deployer.provider!.getBalance(deployer.address);

  console.log("--------------------------------------------------");
  console.log("Deploying TaiAIContract");
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(balance));
  console.log("--------------------------------------------------");

  /**
   * Constructor parameters
   *
   * dao            → temporary DAO (EOA for now)
   * baseResonance  → initial resonance threshold (recommended: 70–100 range)
   */
  const TEMP_DAO = deployer.address;
  const BASE_RESONANCE = 70;

  const TaiAI = await ethers.getContractFactory("TaiAIContract");
  const taiAI = await TaiAI.deploy(TEMP_DAO, BASE_RESONANCE);

  await taiAI.waitForDeployment();

  const address = await taiAI.getAddress();

  console.log("✅ TaiAIContract deployed successfully");
  console.log("📍 Address:", address);
  console.log("🧠 Base Resonance:", BASE_RESONANCE);
  console.log("🏛️ DAO (temporary):", TEMP_DAO);
  console.log("--------------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

