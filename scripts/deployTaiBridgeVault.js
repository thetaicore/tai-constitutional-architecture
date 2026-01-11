// SPDX-License-Identifier: MIT
// TaiBridgeVault deployment script — mainnet ready (CommonJS)
const { ethers, network, run } = require("hardhat");
const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: "../.env" });

// --- Helper to clean Ethereum addresses ---
function cleanAddress(addr, name) {
  if (!addr) throw new Error(`❌ Address for ${name} missing`);
  const cleaned = addr.replace(/\s+/g, "").toLowerCase().trim();
  if (!/^0x[a-f0-9]{40}$/.test(cleaned))
    throw new Error(`❌ Invalid Ethereum address for ${name}: '${addr}'`);
  return cleaned;
}

async function main() {
  if (network.name !== "mainnet") {
    console.log("⚠️ Only deploy on mainnet.");
    return;
  }

  const [deployer] = await ethers.getSigners();
  console.log("--------------------------------------------------");
  console.log("🚀 Deploying TaiBridgeVault");
  console.log("Deployer:", deployer.address);
  console.log("Network:", network.name);
  console.log("--------------------------------------------------");

  // --- Clean all mainnet addresses ---
  const vaultParams = {
    tai: cleanAddress(process.env.TAI_COIN, "TAI_COIN"),
    ai: cleanAddress(process.env.TAI_AI_CONTRACT_ADDRESS, "TAI_AI_CONTRACT_ADDRESS"),
    merkleClaim: cleanAddress(process.env.TAI_MERKLE_CORE_ADDRESS, "TAI_MERKLE_CORE_ADDRESS"),
    governor: cleanAddress(process.env.TAI_GOVERNOR_ADDRESS, "TAI_GOVERNOR_ADDRESS"),
    timelock: cleanAddress(process.env.TAI_TIMELOCK_CONTROLLER_ADDRESS, "TAI_TIMELOCK_CONTROLLER_ADDRESS"),
    dao: cleanAddress(process.env.DAO_ADDRESS, "DAO_ADDRESS"),
    layerZeroEndpoint: cleanAddress(process.env.LAYER_ZERO_ENDPOINT, "LAYER_ZERO_ENDPOINT"),
    pegOracle: cleanAddress(process.env.TAI_PEG_ORACLE_ADDRESS, "TAI_PEG_ORACLE_ADDRESS"),
    vaultMerkle: cleanAddress(process.env.TAI_VAULT_MERKLE_ADDRESS, "TAI_VAULT_MERKLE_ADDRESS"),
    airdropClaim: cleanAddress(process.env.TAI_AIRDROP_CLAIM_ADDRESS, "TAI_AIRDROP_CLAIM_ADDRESS"),
    coinSwap: cleanAddress(process.env.TAI_COIN_SWAP_ADDRESS, "TAI_COIN_SWAP_ADDRESS"),
    mintByResonance: cleanAddress(process.env.MINT_BY_RESONANCE_ADDRESS, "MINT_BY_RESONANCE_ADDRESS"),
    gaslessActivator: cleanAddress(process.env.GASLESS_MERKLE_ACTIVATOR_ADDRESS, "GASLESS_MERKLE_ACTIVATOR_ADDRESS"),
    gaslessActivatorLZ: cleanAddress(process.env.GASLESS_MERKLE_ACTIVATOR_LZ, "GASLESS_MERKLE_ACTIVATOR_LZ"),
    chainRouter: cleanAddress(process.env.TAI_CHAIN_ROUTER, "TAI_CHAIN_ROUTER"),
    crossChainMirror: cleanAddress(process.env.TAI_CROSS_CHAIN_STATE_MIRROR, "TAI_CROSS_CHAIN_STATE_MIRROR"),
    intuitionBridge: cleanAddress(process.env.TAI_INTUITION_BRIDGE_ADDRESS, "TAI_INTUITION_BRIDGE_ADDRESS"),
    vault: cleanAddress(process.env.TAI_VAULT_ADDRESS, "TAI_VAULT_ADDRESS"),
    phaseII: cleanAddress(process.env.TAI_VAULT_PHASE_II_ADDRESS, "TAI_VAULT_PHASE_II_ADDRESS"),
    redemptionVault: cleanAddress(process.env.TAI_COIN_REDEMPTION_VAULT_ADDRESS, "TAI_COIN_REDEMPTION_VAULT_ADDRESS"),
    merkleCore: cleanAddress(process.env.TAI_MERKLE_CORE_ADDRESS, "TAI_MERKLE_CORE_ADDRESS"),
    advancedUSD: cleanAddress(process.env.ADVANCED_USD_ADDRESS, "ADVANCED_USD_ADDRESS"),
    activatedUSD: cleanAddress(process.env.TAI_ACTIVATED_USD_ADDRESS, "TAI_ACTIVATED_USD_ADDRESS"),
    resonanceActivation: cleanAddress(process.env.TAI_RESONANCE_ACTIVATION_ADDRESS, "TAI_RESONANCE_ACTIVATION_ADDRESS"),
    vaultLpAdapter: cleanAddress(process.env.TAI_VAULT_LP_ADAPTER_ADDRESS, "TAI_VAULT_LP_ADAPTER_ADDRESS"),
  };

  const TARGET_CURRENCY = process.env.TAI_TARGET_CURRENCY || "USD";
  const ERC2771_FORWARDER = cleanAddress(process.env.ERC2771_FORWARDER_ADDRESS, "ERC2771_FORWARDER_ADDRESS");

  // --- Use fully qualified contract name to prevent HH701 ---
  const Factory = await ethers.getContractFactory(
    "contracts/funding/TaiBridgeVaults/contracts/TaiBridgeVault.sol:TaiBridgeVault"
  );

  // --- Estimate gas dynamically ---
  let gasLimit;
  try {
    gasLimit = (await Factory.signer.estimateGas(
      Factory.getDeployTransaction(vaultParams, TARGET_CURRENCY, ERC2771_FORWARDER)
    )).toNumber();
    gasLimit = Math.floor(gasLimit * 1.3);
    console.log(`💡 Estimated gas: ${gasLimit}`);
  } catch {
    console.warn("⚠️ Gas estimation failed, using fallback 3_000_000");
    gasLimit = 3_000_000;
  }

  // --- Deploy the contract ---
  const contract = await Factory.deploy(vaultParams, TARGET_CURRENCY, ERC2771_FORWARDER, { gasLimit });
  console.log("💡 Waiting for deployment confirmation...");
  await contract.deployed();
  console.log("✅ TaiBridgeVault deployed at:", contract.address);

  // --- Append deployed address to .env ---
  const envPath = path.join(__dirname, "../.env");
  const vaultVar = "TAI_BRIDGE_VAULT_ADDRESS";
  const envContent = fs.readFileSync(envPath, "utf8");
  if (!envContent.includes(vaultVar)) {
    fs.appendFileSync(envPath, `\n# ===== TaiBridgeVault =====\n${vaultVar}=${contract.address}\n`);
    console.log(`✅ Address appended to .env as ${vaultVar}`);
  } else {
    console.log(`⚠️ ${vaultVar} already exists in .env. Update manually if needed.`);
  }

  console.log("--------------------------------------------------");
}

main().catch(err => {
  console.error("❌ Deployment script failed:", err);
  process.exit(1);
});

