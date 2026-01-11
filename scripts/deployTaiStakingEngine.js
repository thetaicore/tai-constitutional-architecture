require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

function getEnvVar(label) {
    const value = process.env[label];
    if (!value || value === "") throw new Error(`❌ Missing environment variable: ${label}`);
    return value.trim();
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying TaiStakingEngine from:", deployer.address);

    // Use exact env key from your system
    const TAI_COIN_ADDRESS = getEnvVar("TAI_COIN");

    // Deploy TaiStakingEngine contract
    const StakingFactory = await ethers.getContractFactory("TaiStakingEngine", deployer);
    const stakingEngine = await StakingFactory.deploy(TAI_COIN_ADDRESS);

    // Wait for deployment confirmation
    await stakingEngine.deployed();

    // ethers v6: the deployed contract object has `target` for the address
    const stakingEngineAddress = stakingEngine.target || stakingEngine.address;
    console.log(`✅ TaiStakingEngine deployed at: ${stakingEngineAddress}`);

    // Append deployed address to .env for architecture reference
    const ENV_APPEND = `\nTAI_STAKING_ENGINE_ADDRESS=${stakingEngineAddress}\n`;
    fs.appendFileSync("../.env", ENV_APPEND);
    console.log("✅ Address appended to .env for future architecture reference");

    console.log("\n--- Mainnet Integration Check ---");
    console.log("TAI_COIN:", TAI_COIN_ADDRESS);
    console.log("DEPLOYED TAI_STAKING_ENGINE:", stakingEngineAddress);
    console.log("---------------------------------");
}

main()
    .then(() => process.exit(0))
    .catch(err => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });

