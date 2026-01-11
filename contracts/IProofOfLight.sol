// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IProofOfLight — TaiCore-compliant interface
/// @notice Tracks, validates, and manages users’ Proof of Light in the Tai ecosystem
interface IProofOfLight {

    // === EVENTS ===
    event ProofRegistered(address indexed user, uint256 lightScore, uint256 timestamp);
    event ProofValidated(address indexed user, uint256 lightScore, bool isValid, uint256 timestamp);
    event ProofUpdated(address indexed user, uint256 oldScore, uint256 newScore, uint256 timestamp);

    // === PROOF MANAGEMENT ===

    /// @notice Register a Proof of Light for a user (DAO/TAI controlled)
    /// @param user Address of the user
    /// @param lightScore Light score value
    /// @return success True if registration succeeded
    function registerProof(address user, uint256 lightScore) external returns (bool success);

    /// @notice Validate a Proof of Light
    /// @param user Address of the user
    /// @param lightScore Light score to validate
    /// @return isValid True if the proof passes validation
    function validateProof(address user, uint256 lightScore) external view returns (bool isValid);

    /// @notice Fetch the current Proof of Light score for a user
    /// @param user Address of the user
    /// @return lightScore Current proof score
    function getProof(address user) external view returns (uint256 lightScore);

    // === OPTIONAL SYSTEM VISIBILITY ===
    
    /// @notice Fetch total registered proofs (optional)
    /// @return total Number of proofs registered
    function getTotalProofs() external view returns (uint256 total);

    /// @notice Fetch historical LightScore for a user (optional)
    /// @param user Address of the user
    /// @return scores Array of historical LightScore values
    function getLightScoreHistory(address user) external view returns (uint256[] memory scores);
}

