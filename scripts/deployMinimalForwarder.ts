require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying MinimalForwarder from:", deployer.address);

    // Deploy MinimalForwarder contract
    const Forwarder = await ethers.getContractFactory("MinimalForwarder");
    const forwarder = await Forwarder.deploy();
    await forwarder.deployed();
    console.log("✅ MinimalForwarder deployed at:", forwarder.address);

    // Append forwarder address to .env file for easy reference
    const fs = require("fs");
    fs.appendFileSync("../.env", `\nERC2771_FORWARDER_ADDRESS=${forwarder.address}\n`);
    console.log("✅ Address appended to .env");
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });

