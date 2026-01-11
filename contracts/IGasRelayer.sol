// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Tai Gas Relayer Interface
/// @notice Defines gas relayer functions aligned with TaiCore DAO and governance
interface IGasRelayer {
    // Core Gas Relayer Functions
    function relayGas(address user, uint256 amount) external returns (bool);
    function gasBalance(address user) external view returns (uint256);

    // Governance / DAO Control
    function setDAO(address newDAO) external;
    function setOwner(address newOwner) external;
    function setRelayerStatus(address relayer, bool status) external;

    // Metadata & Traceability
    function dao() external view returns (address);
    function owner() external view returns (address);

    /// @notice Checks if a relayer is active or not
    /// @param relayer The address of the relayer to check
    /// @return active True if the relayer is active, false otherwise
    function relayerActive(address relayer) external view returns (bool);

    /// @notice Retrieves the version of the gas relayer contract
    /// @return version The version string of the gas relayer contract
    function gasRelayerVersion() external view returns (string memory);

    // -----------------------------
    // Additional Utility Functions
    // -----------------------------
    /// @notice Returns the total gas balance of all users
    /// @return totalBalance The total gas balance of all users in Wei
    function totalGasBalance() external view returns (uint256);
}

