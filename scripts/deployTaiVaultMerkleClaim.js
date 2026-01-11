require("dotenv").config();
const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Only allow mainnet or Sepolia (safety)
const ALLOWED_CHAIN_IDS = [1, 11155111];

/**
 * Validate environment variable exists
 */
function requireEnv(name) {
    const val = process.env[name];
    if (!val) throw new Error(`❌ Missing env: ${name}`);
    return val;
}

/**
 * Clean Ethereum address from .env
 */
function cleanAddress(addr, name) {
    if (!addr) throw new Error(`❌ Address not set for ${name}`);
    const cleaned = addr.replace(/\s+/g, "").toLowerCase().trim();
    if (!/^0x[a-f0-9]{40}$/.test(cleaned)) {
        throw new Error(`❌ Invalid address for ${name}: ${addr}`);
    }
    return cleaned;
}

async function main() {
    const chainId = (await ethers.provider.getNetwork()).chainId;
    if (!ALLOWED_CHAIN_IDS.includes(Number(chainId))) {
        throw new Error(`❌ Unsafe chainId ${chainId}`);
    }

    // ────────────── Load mainnet-confirmed addresses from env ──────────────
    const FORWARDER = cleanAddress(requireEnv("ERC2771_FORWARDER_ADDRESS"), "ERC2771_FORWARDER_ADDRESS");
    const ORACLE = cleanAddress(requireEnv("TAI_PEG_ORACLE_ADDRESS"), "TAI_PEG_ORACLE_ADDRESS");
    const GOVERNOR = cleanAddress(requireEnv("DAO_ADDRESS"), "DAO_ADDRESS");
    const TAI_AI = cleanAddress(requireEnv("TAI_AI_CONTRACT_ADDRESS"), "TAI_AI_CONTRACT_ADDRESS");

    console.log("--------------------------------------------------");
    console.log("🚀 Deploying TaiVaultMerkleClaimV1");
    console.log("Forwarder:", FORWARDER);
    console.log("Oracle:", ORACLE);
    console.log("Governor:", GOVERNOR);
    console.log("TAI AI:", TAI_AI);
    console.log("Network:", network.name);
    console.log("--------------------------------------------------");

    // ────────────── Deploy contract ──────────────
    const Factory = await ethers.getContractFactory("TaiVaultMerkleClaimV1");

    // Estimate gas with safe buffer
    let gasLimit;
    try {
        gasLimit = (await Factory.signer.estimateGas(Factory.getDeployTransaction(
            FORWARDER, ORACLE, GOVERNOR, TAI_AI
        ))).toNumber();
        gasLimit = Math.floor(gasLimit * 1.2); // 20% buffer
        console.log(`💡 Estimated gas: ${gasLimit}`);
    } catch {
        console.warn("⚠️ Gas estimation failed, using fallback 2_000_000");
        gasLimit = 2_000_000;
    }

    const vault = await Factory.deploy(FORWARDER, ORACLE, GOVERNOR, TAI_AI, { gasLimit });
    console.log("💡 Waiting for deployment confirmation...");
    await vault.deployed();

    console.log("✅ TaiVaultMerkleClaimV1 deployed at:", vault.address);

    // ────────────── Export deployed contract into system variables ──────────────
    const envPath = path.join(__dirname, "../.env");
    const varName = "TAI_VAULT_MERKLE_ADDRESS";
    const envContent = fs.readFileSync(envPath, "utf8");
    if (!envContent.includes(varName)) {
        fs.appendFileSync(envPath, `\n# ===== TaiVaultMerkleClaimV1 =====\n${varName}=${vault.address}\n`);
        console.log(`✅ Address appended to .env as ${varName}`);
    } else {
        console.log(`⚠️ ${varName} already exists in .env. Update manually if needed.`);
    }

    console.log("--------------------------------------------------");
    console.log("📌 Deployment complete. Vault is now live and integrated into your system.");
}

main().catch(err => {
    console.error("❌ Deployment failed:", err);
    process.exit(1);
});

