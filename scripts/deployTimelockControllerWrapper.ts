import hre from "hardhat"; // Import the Hardhat runtime environment
import fs from "fs";

async function main() {
    const ethers = hre.ethers; // ALWAYS use hre.ethers in Hardhat 2.x
    console.log("Ethers object:", ethers);

    const [deployer] = await ethers.getSigners(); // Get deployer's wallet
    console.log("Deploying contracts from:", deployer.address);

    // Deployment parameters
    const MIN_DELAY = 86400; // 1 day
    const PROPOSERS = [deployer.address];
    const EXECUTORS = [deployer.address];
    const ADMIN = deployer.address;
    const JURISDICTION = "Global";

    // Load ERC2771 Forwarder address from .env
    const forwarderAddress = process.env.ERC2771_FORWARDER_ADDRESS;
    if (!forwarderAddress) throw new Error("❌ ERC2771_FORWARDER_ADDRESS missing in .env");
    console.log("Using Forwarder Address:", forwarderAddress);

    // Get the contract factory
    const TimelockFactory = await ethers.getContractFactory("TimelockControllerWrapper", deployer);

    // Deploy contract
    console.log("Deploying TimelockControllerWrapper...");
    const timelock = await TimelockFactory.deploy(
        MIN_DELAY,
        PROPOSERS,
        EXECUTORS,
        ADMIN,
        JURISDICTION,
        forwarderAddress
    );

    await timelock.deployed();
    console.log(`✅ TimelockControllerWrapper deployed at: ${timelock.address}`);

    // Save deployed address to .env
    const envPath = "./.env"; 
    const timelockAddressLine = `TAI_TIMELOCK_CONTROLLER_ADDRESS=${timelock.address}\n`;

    if (!fs.existsSync(envPath)) throw new Error(`❌ .env file not found at ${envPath}`);
    fs.appendFileSync(envPath, timelockAddressLine);
    console.log("✅ Address saved to .env");
}

// Run the deployment
main()
    .then(() => process.exit(0))
    .catch(err => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });

