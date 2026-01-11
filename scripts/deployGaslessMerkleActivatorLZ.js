require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying with account:", deployer.address);

    const VAULT_ADDRESS = process.env.TAI_VAULT_MERKLE_ADDRESS;
    const TAI_ADDRESS = process.env.TAI_ADDRESS;
    const ENDPOINT_ADDRESS = process.env.LAYER_ZERO_ENDPOINT;
    const FORWARDER_ADDRESS = process.env.ERC2771_FORWARDER_ADDRESS;

    if (!VAULT_ADDRESS || !TAI_ADDRESS || !ENDPOINT_ADDRESS || !FORWARDER_ADDRESS) {
        throw new Error("❌ Missing required addresses in .env");
    }

    console.log("Vault:", VAULT_ADDRESS);
    console.log("TAI:", TAI_ADDRESS);
    console.log("Endpoint:", ENDPOINT_ADDRESS);
    console.log("Forwarder:", FORWARDER_ADDRESS);

    const ActivatorFactory = await ethers.getContractFactory("GaslessMerkleActivatorLZ");

    console.log("⏳ Deploying GaslessMerkleActivatorLZ...");
    const activator = await ActivatorFactory.deploy(
        ENDPOINT_ADDRESS,
        VAULT_ADDRESS,
        TAI_ADDRESS,
        FORWARDER_ADDRESS
    );

    await activator.deployed();
    console.log("✅ GaslessMerkleActivatorLZ deployed at:", activator.address);

    // Save deployment info
    const path = "./deployed/GaslessMerkleActivatorLZ.json";
    fs.mkdirSync("./deployed", { recursive: true });
    fs.writeFileSync(path, JSON.stringify({
        address: activator.address,
        deployer: deployer.address,
        vault: VAULT_ADDRESS,
        tai: TAI_ADDRESS,
        forwarder: FORWARDER_ADDRESS,
        endpoint: ENDPOINT_ADDRESS
    }, null, 2));
    console.log(`📦 Deployment info saved to ${path}`);

    console.log("\n📌 EXPORT THIS FOR FUTURE USE:");
    console.log(`GASLESS_MERKLE_ACTIVATOR_LZ=${activator.address}`);
}

main().catch(err => {
    console.error("❌ Deployment failed:", err);
    process.exit(1);
});

