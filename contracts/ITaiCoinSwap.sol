// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ITaiCoinSwap — TaiCore-compliant interface
/// @notice Defines all TAI/USD swap operations with DAO, AI, and governance integration
interface ITaiCoinSwap {

    // === EVENTS ===
    event SwapExecuted(
        address indexed user,
        uint256 usdAmount,
        uint256 taiAmount,
        uint256 timestamp
    );

    event ReverseSwapExecuted(
        address indexed user,
        uint256 taiAmount,
        uint256 usdAmount,
        uint256 timestamp
    );

    event GenesisActivated(address indexed firstUser, uint256 timestamp);

    event MintAuthorityVerified(address indexed taiCoin, address indexed minter);

    event OracleUpdated(address indexed newOracle, uint256 timestamp);

    event GovernorUpdated(address indexed newGovernor, uint256 timestamp);

    event SwapsPaused(bool paused, uint256 timestamp);

    // === SWAP FUNCTIONS ===
    
    /// @notice Swap USD for TaiCoin
    /// @param usdAmount Amount of USD to swap
    function swapUSDforTai(uint256 usdAmount) external;

    /// @notice Swap TaiCoin for USD
    /// @param taiAmount Amount of TaiCoin to swap
    function swapTaiForUSD(uint256 taiAmount) external;

    // === GOVERNANCE & ADMIN FUNCTIONS ===
    
    /// @notice Pause or unpause all swaps (DAO/TAI/Owner)
    /// @param pause True to pause, false to unpause
    function pauseSwaps(bool pause) external;

    /// @notice Set the oracle used for pricing TAI/USD
    /// @param newOracle Address of the new oracle
    function setOracle(address newOracle) external;

    /// @notice Set the governance controller / governor contract
    /// @param newGov Address of the new governor
    function setGovernor(address newGov) external;

    /// @notice Withdraw USD from contract (DAO/TAI controlled)
    /// @param to Recipient address
    /// @param amount Amount to withdraw
    function withdrawUSD(address to, uint256 amount) external;

    // === UTILITY FUNCTIONS ===

    /// @notice Normalize amounts between tokens with different decimals
    /// @param amt Amount to normalize
    /// @param fromD Decimals of source token
    /// @param toD Decimals of destination token
    /// @return Normalized amount
    function _normalize(uint256 amt, uint8 fromD, uint8 toD) external pure returns (uint256);

    /// @notice Optional: Get current swap paused status
    function isPaused() external view returns (bool);

    /// @notice Optional: Get current oracle address
    function getOracle() external view returns (address);

    /// @notice Optional: Get current governor address
    function getGovernor() external view returns (address);
}

