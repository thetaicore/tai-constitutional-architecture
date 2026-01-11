require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying TaiCrossChainStateMirror from:", deployer.address);

    // ✅ Optional: Use a predefined owner from .env or default to deployer
    const OWNER_ADDRESS = process.env.TAI_CROSS_CHAIN_MIRROR_OWNER || deployer.address;
    console.log("Owner for Mirror contract:", OWNER_ADDRESS);

    // ───────────────────────────── DEPLOY CONTRACT ─────────────────────────────
    const MirrorFactory = await ethers.getContractFactory("TaiCrossChainStateMirror");
    const mirror = await MirrorFactory.deploy(OWNER_ADDRESS);

    // Wait for deployment to finish
    await mirror.deployed();

    // ethers v6 safe way to get deployed address
    const deployedAddress = mirror.getAddress ? await mirror.getAddress() : mirror.address;
    console.log("✅ TaiCrossChainStateMirror deployed at:", deployedAddress);

    // ───────────────────────────── SAVE TO ENV ─────────────────────────────
    const envLine = `\nTAI_CROSS_CHAIN_STATE_MIRROR=${deployedAddress}\n`;
    fs.appendFileSync(".env", envLine);
    console.log("✅ Address appended to .env for system reference");
}

// Execute deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });

