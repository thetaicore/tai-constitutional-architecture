require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying TaiCoinRedemptionVault with account:", deployer.address);

    const TAI_COIN_ADDRESS = process.env.TAI_COIN;
    const USDC_ADDRESS = process.env.CANONICAL_USD;
    const GOVERNOR_ADDRESS = process.env.GOVERNOR;
    const TAI_ADDRESS = process.env.TAI_AI_CONTRACT_ADDRESS;
    const MAX_REDEMPTION_LIMIT = process.env.MAX_REDEMPTION_LIMIT;
    const FORWARDER_ADDRESS = process.env.ERC2771_FORWARDER_ADDRESS;

    const required = [
        TAI_COIN_ADDRESS,
        USDC_ADDRESS,
        GOVERNOR_ADDRESS,
        TAI_ADDRESS,
        MAX_REDEMPTION_LIMIT,
        FORWARDER_ADDRESS
    ];

    required.forEach((val, i) => {
        if (!val) throw new Error(`❌ Missing env var index ${i}`);
    });

    console.log("🔗 Using:");
    console.log("TAI:", TAI_COIN_ADDRESS);
    console.log("USD:", USDC_ADDRESS);
    console.log("Governor:", GOVERNOR_ADDRESS);
    console.log("TAI AI:", TAI_ADDRESS);
    console.log("Limit:", MAX_REDEMPTION_LIMIT);
    console.log("Forwarder:", FORWARDER_ADDRESS);

    const Factory = await ethers.getContractFactory("TaiCoinRedemptionVault");
    const vault = await Factory.deploy(
        TAI_COIN_ADDRESS,
        USDC_ADDRESS,
        GOVERNOR_ADDRESS,
        TAI_ADDRESS,
        MAX_REDEMPTION_LIMIT,
        FORWARDER_ADDRESS
    );

    await vault.deployed();   // <-- FIXED

    console.log("✅ TaiCoinRedemptionVault deployed at:", vault.address);
}

main()
    .then(() => process.exit(0))
    .catch(err => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });

