require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying TaiChainRouter from:", deployer.address);

    // ✅ Load mainnet addresses from .env
    const LZ_ENDPOINT = process.env.LAYER_ZERO_ENDPOINT;
    const VAULT_ADDRESS = process.env.TAI_VAULT_ADDRESS;
    const DAO_ADDRESS = process.env.DAO_ADDRESS;
    const FORWARDER = process.env.ERC2771_FORWARDER_ADDRESS;

    if (!LZ_ENDPOINT || !VAULT_ADDRESS || !DAO_ADDRESS || !FORWARDER) {
        throw new Error("❌ Missing required addresses in .env");
    }

    console.log("LayerZero Endpoint:", LZ_ENDPOINT);
    console.log("Vault:", VAULT_ADDRESS);
    console.log("DAO:", DAO_ADDRESS);
    console.log("Forwarder:", FORWARDER);

    // ───────────────────────────── DEPLOY CONTRACT ─────────────────────────────
    const TaiChainRouterFactory = await ethers.getContractFactory("TaiChainRouter");
    const router = await TaiChainRouterFactory.deploy(
        LZ_ENDPOINT,
        VAULT_ADDRESS,
        DAO_ADDRESS,
        FORWARDER
    );

    // Wait for deployment
    await router.deployed();

    // ethers v6 fix: use getAddress() to retrieve deployed contract address
    const deployedAddress = router.getAddress ? await router.getAddress() : router.address;
    console.log("✅ TaiChainRouter deployed at:", deployedAddress);

    // ───────────────────────────── SAVE TO ENV ─────────────────────────────
    const envLine = `\nTAI_CHAIN_ROUTER=${deployedAddress}\n`;
    fs.appendFileSync(".env", envLine);
    console.log("✅ Address appended to .env for system reference");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });

