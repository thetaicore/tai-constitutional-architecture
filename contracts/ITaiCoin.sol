// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ITaiCoin — TaiCore-compliant interface
/// @notice Defines minting and burning for TaiCoin with DAO & TAI integration
interface ITaiCoin {
    /// @notice Mint TaiCoin to a user
    /// @dev Must emit Minted event in implementation
    /// @param to Recipient address
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external;

    /// @notice Burn TaiCoin from a user
    /// @dev Must emit Burned event in implementation
    /// @param from Address to burn from
    /// @param amount Amount to burn
    function burn(address from, uint256 amount) external;

    /// @notice Returns the maximum supply of TaiCoin
    function maxSupply() external view returns (uint256);

    /// @notice Returns the current token version
    function tokenVersion() external view returns (string memory);

    /// @notice Returns the DAO address controlling TaiCoin
    function dao() external view returns (address);
}

