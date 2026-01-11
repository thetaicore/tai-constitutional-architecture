import { ethers, run, network } from "hardhat";

async function main() {
  // Get the deployer account (this uses the local Hardhat accounts by default)
  const [deployer] = await ethers.getSigners();
  
  // Explicitly get the provider
  const provider = ethers.provider;

  // Check if provider is available
  if (!provider) {
    throw new Error("Provider is not available!");
  }

  const net = await provider.getNetwork();

  console.log("========================================");
  console.log("Deploying TaiArchitectureRegistry");
  console.log("Deployer:", deployer.address);
  console.log("Chain ID:", net.chainId.toString());
  console.log("Network:", network.name);
  console.log("========================================");

  // Get the contract factory
  const Registry = await ethers.getContractFactory("TaiArchitectureRegistry");

  // Provide the initialOwner address (in this case, the deployer address)
  const registry = await Registry.deploy(deployer.address);  // Pass the deployer's address as the initialOwner

  await registry.deployed();

  const address = registry.address;
  const tx = registry.deployTransaction;
  if (!tx) throw new Error("Deployment transaction missing");

  const receipt = await tx.wait();
  if (!receipt) throw new Error("No deployment receipt");

  console.log("✅ DEPLOYMENT COMPLETE");
  console.log("Contract Address:", address);
  console.log("TX Hash:", tx.hash);
  console.log("Block Number:", receipt.blockNumber);

  // Verifying contract on Etherscan if using mainnet or testnet
  if (network.name !== "hardhat") {
    console.log("🔍 Verifying on Etherscan...");
    await run("verify:verify", {
      address,
      constructorArguments: [deployer.address],  // Provide initialOwner argument here for verification
    });
    console.log("✅ VERIFIED");
  }

  console.log("--------------------------------------------------");
  console.log("ENV OUTPUT");
  console.log(`TAI_ARCHITECTURE_REGISTRY=${address}`);
  console.log("--------------------------------------------------");
}

main().catch((error) => {
  console.error("❌ DEPLOYMENT FAILED");
  console.error(error);
  process.exitCode = 1;
});

