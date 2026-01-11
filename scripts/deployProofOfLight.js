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
  console.log("Deploying ProofOfLight");
  console.log("Deployer:", deployer.address);
  console.log("--------------------------------------------------");

  const taiCoin = must("TAI_COIN_ADDRESS");
  const dao = must("DAO_ADDRESS");
  const ai = must("TAI_AI_CONTRACT_ADDRESS");

  const merkleClaim = process.env.TAI_VAULT_MERKLE_CLAIM_ADDRESS
    ? ethers.utils.getAddress(process.env.TAI_VAULT_MERKLE_CLAIM_ADDRESS)
    : ethers.constants.AddressZero;

  const coinSwap = process.env.TAI_COIN_SWAP_ADDRESS
    ? ethers.utils.getAddress(process.env.TAI_COIN_SWAP_ADDRESS)
    : ethers.constants.AddressZero;

  const Factory = await ethers.getContractFactory("ProofOfLight", deployer);
  const proof = await Factory.deploy(
    taiCoin,
    dao,
    merkleClaim,
    coinSwap,
    ai
  );

  await proof.deployed();

  console.log("--------------------------------------------------");
  console.log("✅ ProofOfLight deployed successfully");
  console.log("📍 Address:", proof.address);
  console.log("--------------------------------------------------");

  const fs = require("fs");
  fs.appendFileSync(
    "../.env",
    `\nPROOF_OF_LIGHT_ADDRESS=${proof.address}\n`
  );
}

main().catch(err => {
  console.error("❌ Deployment failed:", err);
  process.exit(1);
});

