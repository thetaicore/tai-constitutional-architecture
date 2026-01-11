require("dotenv").config({ path: "../.env" });
const { ethers } = require("hardhat");

const ALLOWED_CHAIN_IDS = [1]; // mainnet only

function requireEnv(name) {
    const v = process.env[name];
    if (!v) throw new Error(`❌ Missing env: ${name}`);
    return v;
}

async function main() {
    const { chainId } = await ethers.provider.getNetwork();
    if (!ALLOWED_CHAIN_IDS.includes(Number(chainId))) {
        throw new Error(`❌ Unsafe chainId ${chainId}`);
    }

    const TRUSTED_FORWARDER = requireEnv("ERC2771_FORWARDER_ADDRESS");
    const USD              = requireEnv("CANONICAL_USD");
    const TAI              = requireEnv("TAI_COIN");
    const ORACLE           = requireEnv("TAI_PEG_ORACLE_ADDRESS");
    const VAULT            = requireEnv("TAI_VAULT_MERKLE_ADDRESS");
    const GOV              = requireEnv("DAO_ADDRESS");
    const TAI_AI           = requireEnv("TAI_AI_CONTRACT_ADDRESS");

    console.log("🚀 Deploying TaiCoinSwap");
    console.log("Forwarder:", TRUSTED_FORWARDER);
    console.log("USD:", USD);
    console.log("TAI:", TAI);
    console.log("Oracle:", ORACLE);
    console.log("Vault:", VAULT);
    console.log("Governor:", GOV);
    console.log("TAI AI:", TAI_AI);

    // 🔴 THIS WAS THE ISSUE — MUST MATCH CONTRACT NAME
    const Factory = await ethers.getContractFactory("TaiCoinSwapV1");

    const swap = await Factory.deploy(
        TRUSTED_FORWARDER,
        USD,
        TAI,
        ORACLE,
        VAULT,
        GOV,
        TAI_AI
    );

    await swap.deployed();
    const addr = swap.address;

    console.log("✅ TaiCoinSwap deployed at:", addr);

    // Grant MINTER_ROLE post-deploy (Option B)
    const taiCoin = await ethers.getContractAt("TaiCoin", TAI);
    const MINTER_ROLE = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes("MINTER_ROLE")
    );

    if (!(await taiCoin.hasRole(MINTER_ROLE, addr))) {
        console.log("🔐 Granting MINTER_ROLE to TaiCoinSwap...");
        await (await taiCoin.grantRole(MINTER_ROLE, addr)).wait();
    }

    console.log("✅ MINTER_ROLE confirmed");
    console.log(`\n📌 EXPORT THIS:\nTAI_COIN_SWAP_ADDRESS=${addr}\n`);
}

main().catch(err => {
    console.error("❌ Deployment failed:", err);
    process.exit(1);
});

