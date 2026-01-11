require("dotenv").config({ path: "../.env" });
const { ethers } = require("hardhat");

async function main() {
    const RPC_URL = process.env.MAINNET_RPC_URL || process.env.SEPOLIA_RPC_URL || process.env.LOCAL_RPC_URL;
    const WALLET_PRIVATE_KEY = process.env.PRIVATE_KEY;
    const ADMIN_ADDRESS = process.env.WALLET_ADDRESS;

    if (!RPC_URL || !WALLET_PRIVATE_KEY || !ADMIN_ADDRESS) {
        throw new Error("❌ Missing required environment variables: RPC_URL, PRIVATE_KEY, WALLET_ADDRESS");
    }

    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(WALLET_PRIVATE_KEY, provider);

    console.log("🚀 Deploying DummyERC20 from:", wallet.address);

    const TOKEN_NAME = "DummyERC20";
    const TOKEN_SYMBOL = "DUMMY";

    // Compile & load artifact
    const artifact = require("../artifacts/contracts/DummyERC20.sol/DummyERC20.json");

    const DummyERC20Factory = new ethers.ContractFactory(
        artifact.abi,
        artifact.bytecode,
        wallet
    );

    console.log("📦 Deploying contract...");
    const dummyToken = await DummyERC20Factory.deploy(TOKEN_NAME, TOKEN_SYMBOL, ADMIN_ADDRESS, {
        gasLimit: 5000000
    });

    await dummyToken.deployed();
    console.log("✅ DummyERC20 deployed at:", dummyToken.address);

    // Assign roles explicitly
    const MINTER_ROLE = await dummyToken.MINTER_ROLE();
    const PAUSER_ROLE = await dummyToken.PAUSER_ROLE();

    console.log("🔑 Assigning MINTER_ROLE...");
    const txMinter = await dummyToken.grantRole(MINTER_ROLE, ADMIN_ADDRESS);
    await txMinter.wait();
    console.log(`✅ MINTER_ROLE granted to: ${ADMIN_ADDRESS}`);

    console.log("🔑 Assigning PAUSER_ROLE...");
    const txPauser = await dummyToken.grantRole(PAUSER_ROLE, ADMIN_ADDRESS);
    await txPauser.wait();
    console.log(`✅ PAUSER_ROLE granted to: ${ADMIN_ADDRESS}`);

    console.log("\n🎉 Deployment complete!");
}

main()
    .then(() => process.exit(0))
    .catch(err => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });

