const { ethers, network } = require("hardhat");
const fs = require("fs");
require("dotenv").config();

function clean(addr, name) {
    if (!addr) throw new Error(`❌ Missing ${name}`);
    const a = addr.trim().toLowerCase();
    if (!/^0x[a-f0-9]{40}$/.test(a))
        throw new Error(`❌ Invalid ${name}: ${addr}`);
    return a;
}

async function main() {
    if (network.name !== "mainnet") {
        throw new Error("❌ This deployment is MAINNET ONLY");
    }

    const [deployer] = await ethers.getSigners();
    console.log("🚀 Deploying TaiCouncil");
    console.log("Deployer:", deployer.address);

    const DAO_ADDRESS = clean(process.env.DAO_ADDRESS, "DAO_ADDRESS");
    const FORWARDER = clean(process.env.ERC2771_FORWARDER_ADDRESS, "ERC2771_FORWARDER_ADDRESS");

    console.log("🔗 Using DAO_ADDRESS:", DAO_ADDRESS);
    console.log("🔗 Using ERC2771_FORWARDER_ADDRESS:", FORWARDER);

    const TaiCouncilFactory = await ethers.getContractFactory("TaiCouncil");

    // DEPLOY CONTRACT
    const taiCouncil = await TaiCouncilFactory.deploy(DAO_ADDRESS, FORWARDER);

    // WAIT FOR MINING
    await taiCouncil.deployed(); // ✅ this is the correct ethers v6 syntax

    console.log("✅ TaiCouncil deployed at:", taiCouncil.target || taiCouncil.address);

    // APPEND TO .ENV
    const envLine = `TAI_COUNCIL_ADDRESS=${taiCouncil.target || taiCouncil.address}\n`;
    const envContent = fs.readFileSync(".env", "utf-8");
    if (!envContent.includes(envLine)) {
        fs.appendFileSync(".env", envLine);
        console.log("✅ Address appended to .env");
    } else {
        console.log("ℹ️ Address already in .env, skipping append");
    }

    console.log("\n--- Mainnet Integration Check ---");
    console.log("DAO_ADDRESS:", DAO_ADDRESS);
    console.log("ERC2771_FORWARDER_ADDRESS:", FORWARDER);
    console.log("DEPLOYED TAI_COUNCIL:", taiCouncil.target || taiCouncil.address);
    console.log("---------------------------------");
}

main().catch(err => {
    console.error("❌ Deployment failed:");
    console.error(err);
    process.exit(1);
});

