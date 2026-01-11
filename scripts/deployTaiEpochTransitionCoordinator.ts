import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const GENESIS_EPOCH = 1;

  console.log(
    "Deploying TaiEpochTransitionCoordinator with:",
    deployer.address,
    "Genesis Epoch:",
    GENESIS_EPOCH
  );

  const Coordinator = await ethers.getContractFactory(
    "TaiEpochTransitionCoordinator"
  );

  const coordinator = await Coordinator.deploy(
    deployer.address,  // Owner address
    GENESIS_EPOCH      // Genesis epoch
  );

  // Wait for the deployment transaction to be mined
  const tx = coordinator.deployTransaction;
  const receipt = await tx.wait();

  console.log(
    "TaiEpochTransitionCoordinator deployed to:",
    coordinator.address // Directly access the address property
  );
  console.log("Deployment confirmed in block:", receipt.blockNumber);
}

main().catch((error) => {
  console.error("❌ Deployment failed!");
  console.error(error);
  process.exitCode = 1;
});

