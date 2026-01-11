require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying TaiIntuitionBridge from:", deployer.address);

    const DAO_ADDRESS = process.env.DAO_ADDRESS;
    const FORWARDER = process.env.ERC2771_FORWARDER_ADDRESS;

    if (!DAO_ADDRESS || !FORWARDER) throw new Error("❌ Missing addresses in .env");

    console.log("DAO Address:", DAO_ADDRESS);
    console.log("Forwarder:", FORWARDER);

    const BridgeFactory = await ethers.getContractFactory("TaiIntuitionBridge");
    const intuitionBridge = await BridgeFactory.deploy(DAO_ADDRESS, FORWARDER);

    // Wait until the deployment transaction is mined
    await intuitionBridge.deployed();

    console.log(`✅ TaiIntuitionBridge deployed at: ${intuitionBridge.address}`);

    // Append deployed address to .env
    fs.appendFileSync(".env", `\nTAI_INTUITION_BRIDGE_ADDRESS=${intuitionBridge.address}\n`);
    console.log("✅ Address appended to .env for future system use");
}

main()
    .then(() => process.exit(0))
    .catch(err => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });

