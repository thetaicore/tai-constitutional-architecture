require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("--------------------------------------------------");
    console.log("Deploying TaiActivatedUSD");
    console.log("Deployer:", deployer.address);
    console.log("--------------------------------------------------");

    const TokenFactory = await ethers.getContractFactory("TaiActivatedUSD", deployer);
    const token = await TokenFactory.deploy();

    // ✅ ethers v5-compatible
    await token.deployed();

    const address = token.address;

    console.log("✅ TaiActivatedUSD deployed successfully");
    console.log("📍 Address:", address);
    console.log("--------------------------------------------------");

    // Append to .env
    const fs = require("fs");
    fs.appendFileSync(
        "../.env",
        `\n# ===== Tai Activated USD =====\nTAI_ACTIVATED_USD_ADDRESS=${address}\n`
    );

    console.log("✅ Address appended to .env");
}

main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exitCode = 1;
});

