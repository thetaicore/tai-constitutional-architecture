import { ethers, network, run } from "hardhat";
import { config } from "dotenv";
import fs from "fs";
import path from "path";

config({ path: "../.env" });

// --- Helper to clean addresses ---
function cleanAddress(addr: string | undefined, name: string): string {
  if (!addr) throw new Error(`❌ Address not set in .env for ${name}`);
  const cleaned = addr.replace(/\s+/g, "").toLowerCase().trim();
  if (!/^0x[a-f0-9]{40}$/.test(cleaned)) throw new Error(`❌ Invalid format for ${name}: ${addr}`);
  return cleaned;
}

async function main() {
  if (network.name !== "mainnet") {
    console.log("⚠️ Only deploy on mainnet.");
    return;
  }

  const [deployer] = await ethers.getSigners();
  console.log("--------------------------------------------------");
  console.log("🚀 Deploying TaiPegOracleInstance");
  console.log("Deployer:", deployer.address);
  console.log("Network:", network.name);
  console.log("--------------------------------------------------");

  // --- Clean mainnet addresses ---
  const ENDPOINT = process.env.LAYER_ZERO_ENDPOINT || "";
  const TRUSTED_FORWARDER = cleanAddress(process.env.ERC2771_FORWARDER_ADDRESS, "ERC2771_FORWARDER_ADDRESS");
  const GOVERNOR = cleanAddress(process.env.TAI_TIMELOCK_CONTROLLER_ADDRESS, "TAI_TIMELOCK_CONTROLLER_ADDRESS");
  const CANONICAL_USD = cleanAddress(process.env.CANONICAL_USD, "CANONICAL_USD");
  const TAI_COIN = cleanAddress(process.env.TAI_COIN, "TAI_COIN");
  const TAI = cleanAddress(process.env.TAI_AI_CONTRACT_ADDRESS, "TAI_AI_CONTRACT_ADDRESS");

  console.log("✅ Addresses cleaned (checksum skipped)");

  // --- Archive link & title ---
  const ARWEAVE_LINK = process.env.TAI_ARCHIVE_2 || "https://arweave.net/VqP1qRPaQYVL9591AJ2xIdKUY5DWPMBvQ9giEpDIPDo";
  const ARWEAVE_TITLE = "The Return";

  const Factory = await ethers.getContractFactory("TaiPegOracleInstance");

  // --- Estimate gas dynamically ---
  let gasLimit: number;
  try {
    gasLimit = (await Factory.signer.estimateGas(
      Factory.getDeployTransaction(
        ENDPOINT,
        TRUSTED_FORWARDER,
        GOVERNOR,
        ARWEAVE_LINK,
        ARWEAVE_TITLE,
        TAI_COIN,
        CANONICAL_USD,
        TAI
      )
    )).toNumber();
    gasLimit = Math.floor(gasLimit * 1.3);
    console.log(`💡 Estimated gas: ${gasLimit}`);
  } catch (err) {
    console.warn("⚠️ Gas estimation failed, using fallback 2_000_000");
    gasLimit = 2_000_000;
  }

  let contract;
  try {
    contract = await Factory.deploy(
      ENDPOINT,
      TRUSTED_FORWARDER,
      GOVERNOR,
      ARWEAVE_LINK,
      ARWEAVE_TITLE,
      TAI_COIN,
      CANONICAL_USD,
      TAI,
      { gasLimit }
    );
    console.log("💡 Waiting for deployment confirmation...");
    await contract.deployed();
  } catch (err: any) {
    console.error("❌ Deployment failed!", err.reason || err.message || err);
    process.exit(1);
  }

  console.log("✅ TaiPegOracleInstance deployed at:", contract.address);

  // --- Append deployed address to .env ---
  const envPath = path.join(__dirname, "../.env");
  const oracleVar = "TAI_PEG_ORACLE_ADDRESS";
  const envContent = fs.readFileSync(envPath, "utf8");
  if (!envContent.includes(oracleVar)) {
    fs.appendFileSync(envPath, `\n# ===== TaiPegOracle =====\n${oracleVar}=${contract.address}\n`);
    console.log(`✅ Address appended to .env as ${oracleVar}`);
  } else {
    console.log(`⚠️ ${oracleVar} already exists in .env. Update manually if needed.`);
  }

  console.log("--------------------------------------------------");

  // --- Optional Phase1 initialization ---
  const zeroAddress = "0x0000000000000000000000000000000000000000";
  if ([TAI_COIN, CANONICAL_USD, TAI].some(addr => addr === zeroAddress)) {
    console.log("⚡ Initializing Phase 1 addresses post-deployment...");
    const tx = await contract.initializePhase1(TAI_COIN, CANONICAL_USD, TAI);
    await tx.wait();
    console.log("✅ Phase 1 initialized successfully");
  }

  // --- Etherscan verification ---
  if (process.env.ETHERSCAN_API_KEY) {
    try {
      console.log("🔍 Verifying on Etherscan...");
      await run("verify:verify", {
        address: contract.address,
        constructorArguments: [
          ENDPOINT,
          TRUSTED_FORWARDER,
          GOVERNOR,
          ARWEAVE_LINK,
          ARWEAVE_TITLE,
          TAI_COIN,
          CANONICAL_USD,
          TAI,
        ],
      });
      console.log("✅ Verified on Etherscan");
    } catch (err: any) {
      console.warn("⚠️ Verification failed:", err.message || err);
    }
  }
}

main().catch((err) => {
  console.error("❌ Deployment script failed:", err);
  process.exitCode = 1;
});

