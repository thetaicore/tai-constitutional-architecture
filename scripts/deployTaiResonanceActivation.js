require("dotenv").config();
const { ethers } = require("hardhat");

function requireEnv(name) {
    const val = process.env[name];
    if (!val) throw new Error(`❌ Missing required environment variable: ${name}`);
    return val;
}

function validateAddress(label, address) {
    if (!address) throw new Error(`❌ ${label} is missing`);
    try {
        return ethers.utils.getAddress(address.trim()); // ethers v5
    } catch {
        throw new Error(`❌ Invalid Ethereum address for ${label}: ${address}`);
    }
}

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("--------------------------------------------------");
    console.log("Deploying TaiResonanceActivation");
    console.log("Deployer:", deployer.address);
    console.log("--------------------------------------------------");

    // ✅ Correct environment variables
    const merkleRoot = requireEnv("TAI_MERKLE_ROOT");
    const dao = validateAddress("DAO_ADDRESS", requireEnv("DAO_ADDRESS"));
    const tai = validateAddress(
        "TAI_AI_CONTRACT_ADDRESS",
        requireEnv("TAI_AI_CONTRACT_ADDRESS")
    );
    const forwarder = validateAddress(
        "ERC2771_FORWARDER_ADDRESS",
        requireEnv("ERC2771_FORWARDER_ADDRESS")
    );

    const Factory = await ethers.getContractFactory(
        "TaiResonanceActivation",
        deployer
    );

    const resonance = await Factory.deploy(
        merkleRoot,
        dao,
        tai,
        forwarder
    );

    await resonance.deployed();

    console.log("✅ TaiResonanceActivation deployed successfully");
    console.log("📍 Address:", resonance.address);
    console.log("--------------------------------------------------");

    // Append to .env
    const fs = require("fs");
    fs.appendFileSync(
        "../.env",
        `\n# ===== Tai Resonance Activation =====\nTAI_RESONANCE_ACTIVATION_ADDRESS=${resonance.address}\n`
    );

    console.log("✅ Address appended to .env");
}

main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exitCode = 1;
});

