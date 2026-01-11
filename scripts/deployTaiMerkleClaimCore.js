require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("--------------------------------------------------");
    console.log("🚀 Deploying TaiMerkleClaimCore");
    console.log("Deployer:", deployer.address);
    console.log("--------------------------------------------------");

    // === Canonical Architecture Inputs ===
    const MERKLE_ROOT = process.env.TAI_MERKLE_ROOT;
    const TAI_ADDRESS = process.env.TAI_AI_CONTRACT_ADDRESS;
    const FORWARDER = process.env.ERC2771_FORWARDER_ADDRESS;
    const GOVERNOR = process.env.GOVERNOR;

    const required = [MERKLE_ROOT, TAI_ADDRESS, FORWARDER, GOVERNOR];
    required.forEach((v, i) => {
        if (!v) throw new Error(`❌ Missing env var index ${i}`);
    });

    console.log("Using:");
    console.log("Merkle Root:", MERKLE_ROOT);
    console.log("TAI AI:", TAI_ADDRESS);
    console.log("Forwarder:", FORWARDER);
    console.log("Governor:", GOVERNOR);

    // Deploy
    const Factory = await ethers.getContractFactory("TaiMerkleClaimCore");
    const core = await Factory.deploy(
        MERKLE_ROOT,
        TAI_ADDRESS,
        FORWARDER
    );

    await core.deployed();

    const address = core.address;

    console.log("--------------------------------------------------");
    console.log("✅ TaiMerkleClaimCore deployed successfully");
    console.log("📍 Address:", address);
    console.log("--------------------------------------------------");

    // Transfer ownership to Governor
    const tx = await core.transferOwnership(GOVERNOR);
    await tx.wait();
    console.log("👑 Ownership transferred to Governor");

    // Append to .env
    const fs = require("fs");
    fs.appendFileSync(
        "../.env",
        `\n# ===== TaiMerkleClaimCore =====\nTAI_MERKLE_CORE_ADDRESS=${address}\n`
    );

    console.log("✅ Address appended to .env");
}

main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exitCode = 1;
});

