// 🔒 TAI CORE — ABSOLUTE CONTRACT SYNCHRONIZATION, ATTESTATION & DEPLOYMENT DIRECTIVE
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Define contract parameters
  const unlockTime = 1760000000;  // Set unlock time in the future
  const daoAddress = deployer.address;  // DAO address for system governance

  // Deploy the Lock contract
  const Lock = await ethers.getContractFactory("Lock");
  const lock = await Lock.deploy(unlockTime, daoAddress, { value: ethers.parseEther("1") });
  await lock.deployed();

  console.log("Lock contract deployed to:", lock.address);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});

