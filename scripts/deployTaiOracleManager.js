require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

function validateAddress(label, address) {
    if (!address) throw new Error(`❌ ${label} is missing`);
    try {
        return ethers.utils.getAddress(address.trim());
    } catch {
        throw new Error(`❌ Invalid Ethereum address for ${label}: ${address}`);
    }
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("--------------------------------------------------");
    console.log("Deploying TaiOracleManager");
    console.log("Deployer:", deployer.address);
    console.log("--------------------------------------------------");

    const DAO_ADDRESS = validateAddress(
        "DAO_ADDRESS",
        process.env.DAO_ADDRESS || deployer.address
    );

    const FORWARDER = validateAddress(
        "ERC2771_FORWARDER_ADDRESS",
        process.env.ERC2771_FORWARDER_ADDRESS
    );

    const OracleFactory = await ethers.getContractFactory("TaiOracleManager", deployer);
    const oracleManager = await OracleFactory.deploy(DAO_ADDRESS, FORWARDER);

    // ⏳ ethers v5 compatible
    await oracleManager.deployed();

    console.log("--------------------------------------------------");
    console.log("✅ TaiOracleManager deployed successfully");
    console.log("📍 Address:", oracleManager.address);
    console.log("👑 DAO:", DAO_ADDRESS);
    console.log("📡 Forwarder:", FORWARDER);
    console.log("--------------------------------------------------");

    // Append to .env
    fs.appendFileSync(
        ".env",
        `\nTAI_ORACLE_MANAGER_ADDRESS=${oracleManager.address}\n`
    );

    console.log("✅ Address appended to .env");
}

main()
    .then(() => process.exit(0))
    .catch(err => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });

