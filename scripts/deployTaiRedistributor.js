require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying TaiRedistributor with account:", deployer.address);

    // === Load all mainnet addresses from .env ===
    const TAI_COIN_ADDRESS = process.env.TAI_COIN;
    const DAO_ADDRESS = process.env.DAO_ADDRESS;
    const TAI_CONTROLLER_ADDRESS = process.env.TAI_AI_CONTRACT_ADDRESS; // using TAI AI Contract as controller
    const MERKLE_CLAIM_ADDRESS = process.env.TAI_VAULT_MERKLE_ADDRESS;
    const COIN_SWAP_ADDRESS = process.env.TAI_COIN_SWAP_ADDRESS;
    const GAS_RELAYER_ADDRESS = process.env.GASLESS_MERKLE_ACTIVATOR_ADDRESS;
    const PROOF_OF_LIGHT_ADDRESS = process.env.PROOF_OF_LIGHT_ADDRESS;
    const MINT_BY_RESONANCE_ADDRESS = process.env.MINT_BY_RESONANCE_ADDRESS;
    const TAI_AI_ADDRESS = process.env.TAI_AI_ADDRESS;
    const FORWARDER_ADDRESS = process.env.ERC2771_FORWARDER_ADDRESS;

    // Validate addresses
    [
        TAI_COIN_ADDRESS, DAO_ADDRESS, TAI_CONTROLLER_ADDRESS, MERKLE_CLAIM_ADDRESS,
        COIN_SWAP_ADDRESS, GAS_RELAYER_ADDRESS, PROOF_OF_LIGHT_ADDRESS,
        MINT_BY_RESONANCE_ADDRESS, TAI_AI_ADDRESS, FORWARDER_ADDRESS
    ].forEach((addr, i) => {
        if (!addr || addr === "0x0000000000000000000000000000000000000000") {
            throw new Error(`❌ Invalid address at index ${i}`);
        }
    });

    // Deploy TaiRedistributor
    const TaiRedistributor = await ethers.getContractFactory("TaiRedistributor");
    const redistributor = await TaiRedistributor.deploy(
        TAI_COIN_ADDRESS,
        DAO_ADDRESS,
        TAI_CONTROLLER_ADDRESS,
        MERKLE_CLAIM_ADDRESS,
        COIN_SWAP_ADDRESS,
        GAS_RELAYER_ADDRESS,
        PROOF_OF_LIGHT_ADDRESS,
        MINT_BY_RESONANCE_ADDRESS,
        TAI_AI_ADDRESS,
        FORWARDER_ADDRESS
    );

    await redistributor.deployed();
    console.log("✅ TaiRedistributor deployed at:", redistributor.address);

    // Append address to .env for system ingestion
    const envAppend = `\n# ===== TaiRedistributor =====\nTAI_REDISTRIBUTOR_ADDRESS=${redistributor.address}\n`;
    fs.appendFileSync("../.env", envAppend);
    console.log("✅ Address appended to .env");
}

main().then(() => process.exitCode = 0).catch(err => {
    console.error("❌ Deployment failed:", err);
    process.exitCode = 1;
});

