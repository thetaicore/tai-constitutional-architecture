import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying TaiConsentManifold with:", deployer.address);

  const ConsentManifold = await ethers.getContractFactory("TaiConsentManifold");
  const consentManifold = await ConsentManifold.deploy(deployer.address);

  await consentManifold.deployTransaction.wait(); // Wait for the deployment transaction to be mined

  console.log("TaiConsentManifold deployed to:", consentManifold.address); // Use 'address' instead of 'getAddress'
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

