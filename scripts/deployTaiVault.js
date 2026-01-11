require("dotenv").config({ path: "./.env" });
const fs = require("fs");
const { ethers, network } = require("hardhat");

/* ───────── Helpers ───────── */
function requireEnv(name) {
  const val = process.env[name];
  if (!val) throw new Error(`❌ Missing required environment variable: ${name}`);
  return val;
}

function cleanAddress(address) {
  return address.replace(/['"`\s]/g, "").trim();
}

/* ───────── Main ───────── */
async function main() {
  console.log("--------------------------------------------------");
  console.log("🚀 Deploying TaiVault (MAINNET READY)");
  console.log("🌐 Network:", network.name);
  console.log("--------------------------------------------------");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer address:", deployer.address);

  /* ───────── Load and validate addresses ───────── */
  const COLLATERAL_TOKEN = ethers.utils.getAddress(
    cleanAddress(requireEnv("LP_TOKEN_ADDRESS"))
  );
  const TAI_COIN = ethers.utils.getAddress(cleanAddress(requireEnv("TAI_COIN")));
  const ORACLE = ethers.utils.getAddress(
    cleanAddress(requireEnv("BOOTSTRAP_PEG_ORACLE_ADDRESS"))
  );
  const TAI_AI = ethers.utils.getAddress(cleanAddress(requireEnv("TAI_AI")));
  const FORWARDER = ethers.utils.getAddress(
    cleanAddress(requireEnv("ERC2771_FORWARDER_ADDRESS"))
  );

  console.log("✅ All addresses cleaned and validated");

  /* ───────── Deploy Contract ───────── */
  const TaiVaultFactory = await ethers.getContractFactory("TaiVault", deployer);

  const taiVault = await TaiVaultFactory.deploy(
    COLLATERAL_TOKEN,
    TAI_COIN,
    ORACLE,
    TAI_AI,
    FORWARDER
  );

  // Wait for deployment to complete
  await taiVault.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ TaiVault deployed successfully");
  console.log("📍 Address:", taiVault.address);
  console.log("--------------------------------------------------");

  /* ───────── Persist in .env ───────── */
  fs.appendFileSync(
    "./.env",
    `
# ------------------------------
# TaiVault
# ------------------------------
TAI_VAULT_ADDRESS=${taiVault.address}
`
  );

  console.log("✅ Address appended to .env");
}

/* ───────── Execute ───────── */
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });

