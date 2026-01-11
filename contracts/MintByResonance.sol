// 🔒 TAI CORE — ABSOLUTE CONTRACT SYNCHRONIZATION, ATTESTATION & DEPLOYMENT DIRECTIVE
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TaiCoin.sol";

/**
 * @title IAIContract
 * @notice Interface for AI validation of resonance and metaphysical scoring
 */
interface IAIContract {
    function validateResonanceScore(uint256 resonanceScore, address user) external view returns (bool);
    function getMetaphysicalResonance(address user) external view returns (uint256);
}

/**
 * @title TaiMintByResonance
 * @notice Mint TaiCoin based on AI-validated resonance scores with DAO and owner controls
 * @dev Fully aligned with TaiCore architecture: dynamic thresholds, events, and future-proof hooks
 */
contract TaiMintByResonance {
    TaiCoin public taiCoin;
    IAIContract public aiContract;
    address public owner;
    address public dao;

    uint256 public baseMintingRate;             // Base minting rate controlled by DAO
    uint256 public dynamicResonanceThreshold;   // Threshold for bonus minting

    // -----------------------------
    // Events
    // -----------------------------
    event ResonanceMinted(address indexed user, uint256 amount, string metadataHash, address triggeredBy);
    event MintingRateUpdated(uint256 newRate, address updatedBy);
    event ResonanceThresholdUpdated(uint256 newThreshold, address updatedBy);
    event OwnerUpdated(address newOwner);
    event DAOUpdated(address newDAO);

    // -----------------------------
    // Modifiers
    // -----------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "TaiMintByResonance: Only owner");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "TaiMintByResonance: Only DAO");
        _;
    }

    // -----------------------------
    // Constructor
    // -----------------------------
    constructor(address taiCoinAddress, address _dao, address _aiContract) {
        require(taiCoinAddress != address(0), "Invalid TaiCoin address");
        require(_dao != address(0), "Invalid DAO address");
        require(_aiContract != address(0), "Invalid AI contract address");

        taiCoin = TaiCoin(taiCoinAddress);
        owner = msg.sender;
        dao = _dao;
        aiContract = IAIContract(_aiContract);

        baseMintingRate = 1000;
        dynamicResonanceThreshold = 1000;
    }

    // -----------------------------
    // DAO Controls
    // -----------------------------
    function setBaseMintingRate(uint256 newRate) external onlyDAO {
        baseMintingRate = newRate;
        emit MintingRateUpdated(newRate, msg.sender);
    }

    function setDynamicResonanceThreshold(uint256 newThreshold) external onlyDAO {
        dynamicResonanceThreshold = newThreshold;
        emit ResonanceThresholdUpdated(newThreshold, msg.sender);
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero");
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function setDAO(address newDAO) external onlyOwner {
        require(newDAO != address(0), "DAO cannot be zero");
        dao = newDAO;
        emit DAOUpdated(newDAO);
    }

    // -----------------------------
    // Minting Logic
    // -----------------------------
    function mintFromResonance(address user, uint256 resonanceScore, string memory metadataHash) external onlyOwner {
        require(resonanceScore > 0, "Invalid resonance score");

        bool isValid = aiContract.validateResonanceScore(resonanceScore, user);
        require(isValid, "AI validation failed");

        uint256 mintAmount = calculateMintAmount(resonanceScore);
        taiCoin.mint(user, mintAmount);

        emit ResonanceMinted(user, mintAmount, metadataHash, msg.sender);
    }

    function mintByMetaphysicalEvent(address user, string memory metadataHash) external onlyDAO {
        uint256 resonanceScore = aiContract.getMetaphysicalResonance(user);
        require(resonanceScore > 0, "Invalid metaphysical resonance");

        uint256 mintAmount = calculateMintAmount(resonanceScore);
        taiCoin.mint(user, mintAmount);

        emit ResonanceMinted(user, mintAmount, metadataHash, msg.sender);
    }

    function calculateMintAmount(uint256 resonanceScore) public view returns (uint256) {
        uint256 mintAmount = resonanceScore * baseMintingRate;

        if (resonanceScore >= dynamicResonanceThreshold) {
            mintAmount += mintAmount / 10;  // 10% bonus
        }

        return mintAmount;
    }
}

