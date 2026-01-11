// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IMintByResonance — TaiCore-compliant interface for AI-validated token minting
/// @notice Handles minting of TaiCoin based on resonance scores validated by AI, with DAO governance
interface IMintByResonance {

    // === EVENTS ===
    event ResonanceMinted(address indexed user, uint256 amount, string metadataHash, uint256 timestamp);
    event MintingRateUpdated(uint256 newRate, uint256 timestamp);
    event ResonanceThresholdUpdated(uint256 newThreshold, uint256 timestamp);

    // === DAO / ADMIN FUNCTIONS ===

    /// @notice Update the base minting rate (DAO-controlled)
    /// @param newRate New base rate for resonance-based minting
    function setBaseMintingRate(uint256 newRate) external;

    /// @notice Update the dynamic resonance threshold (DAO-controlled)
    /// @param newThreshold New threshold for bonus minting
    function setDynamicResonanceThreshold(uint256 newThreshold) external;

    // === MINTING FUNCTIONS ===

    /// @notice Mint TaiCoin based on a user’s resonance score, validated via AI
    /// @param user Recipient address
    /// @param resonanceScore Validated resonance score
    /// @param metadataHash Optional metadata or IPFS hash
    function mintFromResonance(address user, uint256 resonanceScore, string memory metadataHash) external;

    /// @notice Mint TaiCoin based on metaphysical events (DAO- or AI-driven)
    /// @param user Recipient address
    /// @param metadataHash Optional metadata or IPFS hash
    function mintByMetaphysicalEvent(address user, string memory metadataHash) external;

    // === VIEW FUNCTIONS ===

    /// @notice Calculate the mint amount based on resonance score and thresholds
    /// @param resonanceScore User resonance score
    /// @return mintAmount Computed mint amount
    function calculateMintAmount(uint256 resonanceScore) external view returns (uint256);
}

