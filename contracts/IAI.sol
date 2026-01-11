// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Tai AI Core Interface
/// @notice Defines AI functions aligned with TaiCore governance, DAO, and dynamic thresholds
interface ITaiAI {
    // -----------------------------
    // Core AI Functions
    // -----------------------------
    function processIntentSignal(address user, uint256 score, string calldata signalType) external;
    function validateProposal(
        string calldata description,
        address target,
        bytes calldata callData,
        uint256 action
    ) external view returns (bool);
    function getMetaphysicalResonance(address user) external view returns (uint256);
    function validateResonanceScore(uint256 resonanceScore, address user) external view returns (bool);

    // -----------------------------
    // Governance / DAO Control
    // -----------------------------
    function setBaseResonance(uint256 newBase) external;
    function setDAO(address newDAO) external;
    function setOwner(address newOwner) external;

    // -----------------------------
    // Metadata & Traceability
    // -----------------------------
    function baseResonance() external view returns (uint256);
    function dao() external view returns (address);
    function owner() external view returns (address);
}

