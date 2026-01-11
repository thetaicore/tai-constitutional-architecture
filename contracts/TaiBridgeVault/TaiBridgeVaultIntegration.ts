import { ethers } from "hardhat";
import { TaiBridgeVault } from "../typechain";

async function interactWithTaiBridgeVault() {
  const [deployer] = await ethers.getSigners();
  const vaultAddress = process.env.TAI_BRIDGE_VAULT_ADDRESS; // Address of the deployed contract

  const FORWARDER_ADDRESS = process.env.FORWARDER_ADDRESS;  // Ensure forwarder address is available

  // Create an instance of the contract using the forwarder
  const TaiBridgeVaultFactory = await ethers.getContractFactory("TaiBridgeVault");
  const vault = TaiBridgeVaultFactory.attach(vaultAddress).connect(deployer);

  // Example: Calling a function from the TaiBridgeVault
  // Make sure to include the forwarder in the setup if the contract supports ERC2771
  const amount = ethers.utils.parseUnits("100", 18); // Example amount to bridge
  const destination = "Polygon";  // Example destination

  // Call bridge function using the gasless method (ensure the message sender is handled)
  const proof = []; // Include Merkle proof if needed
  const tx = await vault.bridgeToFiat(amount, destination, proof);
  await tx.wait();

  console.log(`✅ Bridge transaction successful. Transaction hash: ${tx.hash}`);
}

interactWithTaiBridgeVault().catch((error) => {
  console.error(error);
  process.exit(1);
});

