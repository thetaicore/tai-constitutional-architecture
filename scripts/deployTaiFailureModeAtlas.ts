import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying TaiFailureModeAtlas with:", deployer.address);

  const Atlas = await ethers.getContractFactory("TaiFailureModeAtlas");
  const atlas = await Atlas.deploy(deployer.address);

  await atlas.deployTransaction.wait(); // Wait for the deployment transaction to be mined

  console.log("TaiFailureModeAtlas deployed to:", atlas.address); // Use 'address' instead of 'getAddress'
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

