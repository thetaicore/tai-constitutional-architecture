import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying TaiFinalitySeal with:", deployer.address);

  // Create a contract factory for TaiFinalitySeal
  const Seal = await ethers.getContractFactory("TaiFinalitySeal");

  // Deploy the contract, passing the deployer's address as the initial owner
  const seal = await Seal.deploy(deployer.address);

  // Wait for the contract deployment to complete
  await seal.deployTransaction.wait();

  // Log the contract address once it's deployed
  console.log("TaiFinalitySeal deployed to:", seal.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

