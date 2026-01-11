require("dotenv").config({ path: "./.env" });
const fs = require("fs");
const { ethers, network } = require("hardhat");

// -----------------------------
// Helpers
// -----------------------------
function requireEnv(name) {
  const val = process.env[name];
  if (!val) throw new Error(`❌ Missing required env var: ${name}`);
  return val;
}

function appendEnv(key, value) {
  fs.appendFileSync(
    "./.env",
    `\n# ------------------------------\n# ${key}\n# ------------------------------\n${key}=${value}\n`
  );
  console.log(`✅ ${key} appended to .env`);
}

// -----------------------------
// Main
// -----------------------------
async function main() {
  console.log("--------------------------------------------------");
  console.log("🚀 Deploying TaiVaultLiquidityAdapter (BOOTSTRAP)");
  console.log("🌐 Network:", network.name);
  console.log("--------------------------------------------------");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const DUMMY_LP = requireEnv("DUMMY_LP_ADDRESS");
  console.log("✅ Using DummyLP:", DUMMY_LP);

  const AdapterFactory = await ethers.getContractFactory(
    "TaiVaultLiquidityAdapter",
    deployer
  );

  const adapter = await AdapterFactory.deploy(DUMMY_LP);

  // ✅ ethers v5
  await adapter.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ TaiVaultLiquidityAdapter deployed successfully");
  console.log("📍 Address:", adapter.address);
  console.log("--------------------------------------------------");

  appendEnv("TAI_VAULT_LP_ADAPTER_ADDRESS", adapter.address);

  console.log("⚠️ Bootstrap adapter deployed");
  console.log("➡️ registerLP(realPair) when LP exists");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Deployment failed:", err);
    process.exit(1);
  });

