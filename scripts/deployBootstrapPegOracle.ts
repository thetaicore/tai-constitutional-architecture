import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const balance = await deployer.provider!.getBalance(deployer.address);

  console.log("--------------------------------------------------");
  console.log("Deploying BootstrapPegOracle");
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.utils.formatEther(balance));
  console.log("--------------------------------------------------");

  const Bootstrap = await ethers.getContractFactory("BootstrapPegOracle");
  const oracle = await Bootstrap.deploy();

  // ⏳ ethers v5 compatible
  await oracle.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ BootstrapPegOracle deployed successfully");
  console.log("📍 Address:", oracle.address);
  console.log("--------------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

