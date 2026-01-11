// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Tai AI Interface (Canonical)
/// @notice Unified AI authority for resonance + governance validation
interface ITaiAI {
    /*───────────────────────────── RESONANCE ─────────────────────────────*/
    function validateResonanceScore(uint256 resonanceScore, address user) external view returns (bool);
    function getBaseResonance() external view returns (uint256);
    function setBaseResonance(uint256 newBase) external;

    /*───────────────────────────── GOVERNANCE ─────────────────────────────*/
    function validateProposal(
        string calldata description,
        address target,
        bytes calldata callData,
        uint256 action
    ) external view returns (bool);

    /*───────────────────────────── ADMIN ─────────────────────────────*/
    function setDAO(address newDAO) external;
}

/// @title TaiAIContract
/// @notice Canonical on-chain resonance & governance authority for TaiCore
/// @dev Off-chain AI computes scores, this contract enforces thresholds & policy
contract TaiAIContract is ITaiAI {

    address public owner;
    address public dao;

    /// @notice Minimum resonance score required for activation/minting
    uint256 public baseResonance;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event BaseResonanceUpdated(uint256 newBase);
    event DAOUpdated(address indexed newDAO);
    event OwnerUpdated(address indexed newOwner);

    /*───────────────────────────── MODIFIERS ─────────────────────────────*/
    modifier onlyOwner() {
        require(msg.sender == owner, "TaiAI: only owner");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "TaiAI: only DAO");
        _;
    }

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(address _dao, uint256 _baseResonance) {
        require(_dao != address(0), "DAO cannot be zero");
        owner = msg.sender;
        dao = _dao;
        baseResonance = _baseResonance;
    }

    /*───────────────────────────── DAO CONTROL ─────────────────────────────*/
    function setBaseResonance(uint256 newBase) external override onlyDAO {
        baseResonance = newBase;
        emit BaseResonanceUpdated(newBase);
    }

    function setDAO(address newDAO) external override onlyOwner {
        require(newDAO != address(0), "DAO cannot be zero");
        dao = newDAO;
        emit DAOUpdated(newDAO);
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero");
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /*───────────────────────────── AI VALIDATION ─────────────────────────────*/

    /// @notice Used by ProofOfLight, ResonanceActivation, MintByResonance
    function validateResonanceScore(
        uint256 resonanceScore,
        address /* user */
    ) external view override returns (bool) {
        return resonanceScore >= baseResonance;
    }

    function getBaseResonance() external view override returns (uint256) {
        return baseResonance;
    }

    /// @notice Used by TaiDAO to validate governance proposals
    /// @dev Placeholder logic — can be upgraded to AI rules later
    function validateProposal(
        string calldata /* description */,
        address target,
        bytes calldata /* callData */,
        uint256 /* action */
    ) external view override returns (bool) {
        // Hard safety rule: no zero-address calls
        if (target == address(0)) return false;

        // AI policy hook — currently permissive by design
        return true;
    }
}

