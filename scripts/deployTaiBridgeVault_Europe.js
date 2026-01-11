require("dotenv").config({ path: "../.env" });
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    console.log("🚀 Deploying TaiBridgeVault_Europe");

    const [deployer] = await ethers.getSigners();
    console.log("Deployer:", deployer.address);

    const ENDPOINT = process.env.LZ_ENDPOINT_MAINNET;
    const FORWARDER = process.env.FORWARDER_ADDRESS;

    if (!ENDPOINT || !FORWARDER) {
        throw new Error("❌ Missing required environment variables");
    }

    const Factory = await ethers.getContractFactory("TaiBridgeVault_Europe");
    const vault = await Factory.deploy(ENDPOINT, FORWARDER);
    await vault.deployed();

    console.log("✅ TaiBridgeVault_Europe deployed at:", vault.address);
    console.log("👑 Governor set to:", deployer.address);

    const output = {
        network: "mainnet",
        contract: "TaiBridgeVault_Europe",
        address: vault.address,
        governor: deployer.address,
        deployedAt: new Date().toISOString()
    };

    fs.writeFileSync(
        "./deployed/TaiBridgeVault_Europe.json",
        JSON.stringify(output, null, 2)
    );
}

main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
});

