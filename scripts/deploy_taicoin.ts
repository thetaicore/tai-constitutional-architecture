import "dotenv/config";
import { ethers, run, network } from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  console.log("=== TaiCore TaiCoin Deployment ===");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // -----------------------------
  // Deploy TaiCoinInstance
  // -----------------------------
  const TaiCoinFactory = await ethers.getContractFactory("TaiCoinInstance");
  const taiCoin = await TaiCoinFactory.deploy();
  await taiCoin.deployed();  // Ensure contract is deployed

  const taiCoinAddress = await taiCoin.address;
  console.log("TaiCoinInstance deployed at:", taiCoinAddress);

  // -----------------------------
  // Deploy TaiAI (External Dependency) with fully qualified name
  // -----------------------------
  const TaiAIFactory = await ethers.getContractFactory("TaiAIContract", "contracts/IAIContract.sol");

  // Set the DAO address and baseResonance value here
  const daoAddress = deployer.address; // Or provide the actual DAO address
  const baseResonance = 100; // Example value, replace with your desired value

  const taiAI = await TaiAIFactory.deploy(daoAddress, baseResonance);
  await taiAI.deployed();  // Ensure contract is deployed

  const taiAIAddress = await taiAI.address;
  console.log("TaiAI deployed at:", taiAIAddress);

  // -----------------------------
  // Link TaiAI to TaiCoin
  // -----------------------------
  const txLinkAI = await taiCoin.setTaiAI(taiAIAddress);
  await txLinkAI.wait();
  console.log("TaiAI linked to TaiCoin");

  // -----------------------------
  // Ensure deployer has MINTER_ROLE
  // -----------------------------
  const minterRole = await taiCoin.MINTER_ROLE();
  const hasRole = await taiCoin.hasRole(minterRole, deployer.address);

  if (!hasRole) {
    const grantTx = await taiCoin.grantRole(minterRole, deployer.address);
    await grantTx.wait();
    console.log("MINTER_ROLE granted to deployer");
  } else {
    console.log("Deployer already has MINTER_ROLE");
  }

  // -----------------------------
  // Optional: Save Deployment Info
  // -----------------------------
  const deployInfo = {
    TaiCoin: taiCoinAddress,
    TaiAI: taiAIAddress,
    deployer: deployer.address,
    network: network.name,
  };

  const deployPath = path.join(__dirname, "../deployed/TaiCoin.json");
  fs.mkdirSync(path.dirname(deployPath), { recursive: true });
  fs.writeFileSync(deployPath, JSON.stringify(deployInfo, null, 2));
  console.log(`Deployment info saved to ${deployPath}`);

  // -----------------------------
  // Etherscan Verification (Mainnet / Sepolia)
  // -----------------------------
  if (network.name === "mainnet" || network.name === "sepolia") {
    console.log("Verifying contracts on Etherscan...");

    await verifyContract(taiCoinAddress);
    await verifyContract(taiAIAddress);
  }

  console.log("=== TaiCoin Deployment Complete ===");
}

async function verifyContract(address: string) {
  try {
    await run("verify:verify", {
      address,
      constructorArguments: [],
    });
    console.log("Verified:", address);
  } catch (err: any) {
    console.error("Verification failed for", address, err.message || err);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

