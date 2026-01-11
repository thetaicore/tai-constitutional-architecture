require("dotenv").config();
const { ethers } = require("hardhat");

function must(name) {
  const v = process.env[name];
  if (!v) throw new Error(`❌ Missing env var: ${name}`);
  return ethers.utils.getAddress(v.trim());
}

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("--------------------------------------------------");
  console.log("Deploying AdvancedUSDStablecoin");
  console.log("Deployer:", deployer.address);
  console.log("--------------------------------------------------");

  const TAI_ADDRESS = must("TAI_AI_CONTRACT_ADDRESS"); // TAI decision engine
  const DAO_ADDRESS = must("DAO_ADDRESS");

  const TOKEN_NAME = "AdvancedUSDStablecoin";
  const TOKEN_SYMBOL = "AUSD";
  const MAX_SUPPLY = ethers.utils.parseUnits("1000000000", 6); // 1B, 6 decimals

  const Factory = await ethers.getContractFactory("AdvancedUSDStablecoin", deployer);
  const stablecoin = await Factory.deploy(
    TOKEN_NAME,
    TOKEN_SYMBOL,
    MAX_SUPPLY,
    TAI_ADDRESS,
    DAO_ADDRESS
  );

  await stablecoin.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ AdvancedUSDStablecoin deployed successfully");
  console.log("📍 Address:", stablecoin.address);
  console.log("--------------------------------------------------");

  // Assign roles to deployer (can later transfer to DAO / Timelock)
  const MINTER_ROLE = await stablecoin.MINTER_ROLE();
  const ANONYMOUS_MINTER_ROLE = await stablecoin.ANONYMOUS_MINTER_ROLE();
  const PAUSER_ROLE = await stablecoin.PAUSER_ROLE();

  await stablecoin.grantRole(MINTER_ROLE, deployer.address);
  await stablecoin.grantRole(ANONYMOUS_MINTER_ROLE, deployer.address);
  await stablecoin.grantRole(PAUSER_ROLE, deployer.address);

  console.log("✅ Roles granted to deployer");

  // OPTIONAL: initial mint (can comment out if you want zero-supply start)
  const initialMint = ethers.utils.parseUnits("100000", 6);
  await stablecoin.mint(deployer.address, initialMint);

  console.log("✅ Initial mint:", ethers.utils.formatUnits(initialMint, 6), "AUSD");

  // Persist address
  const fs = require("fs");
  fs.appendFileSync(
    "../.env",
    `\nADVANCED_USD_ADDRESS=${stablecoin.address}\n`
  );
}

main().catch(err => {
  console.error("❌ Deployment failed:", err);
  process.exit(1);
});

