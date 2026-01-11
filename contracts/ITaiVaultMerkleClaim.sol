// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ITaiVaultMerkleClaim — TaiCore-compliant Merkle claim interface
/// @notice Handles ETH and ERC20 claims via Merkle proofs, fully auditable
interface ITaiVaultMerkleClaim {

    // === EVENTS ===
    event ETHClaimed(address indexed user, uint256 amount, bytes32 indexed leaf, uint256 timestamp);
    event ERC20Claimed(address indexed user, address indexed token, uint256 amount, bytes32 indexed leaf, uint256 timestamp);

    // === CLAIM FUNCTIONS ===

    /// @notice Claim ETH using a Merkle proof
    /// @param amount Amount of ETH to claim
    /// @param proof Merkle proof validating the claim
    function claimETH(uint256 amount, bytes32[] calldata proof) external;

    /// @notice Claim ERC20 token using a Merkle proof
    /// @param token Address of ERC20 token
    /// @param amount Amount to claim
    /// @param proof Merkle proof validating the claim
    function claimERC20(address token, uint256 amount, bytes32[] calldata proof) external;

    // === READ FUNCTIONS ===

    /// @notice Check if a user has already claimed
    /// @param user Address of the user
    /// @return claimed True if user has claimed, false otherwise
    function hasClaimed(address user) external view returns (bool);

    /// @notice Optional: Get historical claimed amounts per user (future-proofing)
    /// @param user Address of the user
    /// @return ethClaimed Total ETH claimed by user
    /// @return erc20Claimed List of token addresses and amounts claimed by the user
    function getClaimHistory(address user) external view returns (uint256 ethClaimed, ClaimHistory[] memory erc20Claimed);

    // === STRUCTS ===

    /// @dev Struct for holding ERC20 claim history
    struct ClaimHistory {
        address token; // ERC20 token address
        uint256 amount; // Amount claimed for that token
    }
}

