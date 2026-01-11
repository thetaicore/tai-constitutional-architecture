const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const adapterAddress = process.env.TAI_VAULT_LP_ADAPTER_ADDRESS;
  const lpAddress = process.env.LP_TOKEN_ADDRESS;

  console.log("Adapter:", adapterAddress);
  console.log("LP Token:", lpAddress);

  // Get the deployed adapter contract
  const adapter = await ethers.getContractAt(
    "TaiVaultLiquidityAdapter",
    adapterAddress
  );

  // 1️⃣ Register the LP token
  console.log("Registering LP...");
  const tx1 = await adapter.registerLP(lpAddress);
  await tx1.wait();
  console.log("✅ LP registered");

  // 2️⃣ Refresh LP info inside the adapter
  console.log("Refreshing LP info...");
  const tx2 = await adapter.refreshLPInfo();
  await tx2.wait();
  console.log("✅ LP info refreshed");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });

