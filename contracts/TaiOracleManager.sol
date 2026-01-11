// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 * @title TaiOracleManager
 * @notice Tracks and verifies real-time prices for collateral assets using Chainlink.
 * @dev Fully ERC2771Context ready for meta-transactions
 */
contract TaiOracleManager is ERC2771Context {
    struct OracleFeed {
        AggregatorV3Interface feed;
        uint8 decimals;
        bool isActive;
        uint256 lastUpdated;
    }

    mapping(bytes32 => OracleFeed[]) public oracles; // asset symbol hash => list of oracle feeds
    bytes32[] public trackedAssets;
    address public dao;
    uint256 public priceUpdateThreshold = 5; // Minimum price change (%) to trigger events

    event OracleUpdated(bytes32 indexed assetSymbol, address feed, uint8 decimals);
    event OracleRemoved(bytes32 indexed assetSymbol);
    event PriceUpdated(bytes32 indexed assetSymbol, uint256 newPrice);
    event PriceThresholdTriggered(bytes32 indexed assetSymbol, uint256 price);
    event DAOUpdated(address newDAO);
    event PriceUpdateThresholdSet(uint256 newThreshold);

    modifier onlyDAO() {
        require(_msgSender() == dao, "Only DAO");
        _;
    }

    constructor(address _dao, address _forwarder) ERC2771Context(_forwarder) {
        require(_dao != address(0), "Invalid DAO");
        dao = _dao;
    }

    /*───────────────────────────── DAO FUNCTIONS ─────────────────────────────*/
    function updateDAO(address _newDAO) external onlyDAO {
        require(_newDAO != address(0), "Invalid DAO");
        dao = _newDAO;
        emit DAOUpdated(_newDAO);
    }

    function setPriceUpdateThreshold(uint256 threshold) external onlyDAO {
        priceUpdateThreshold = threshold;
        emit PriceUpdateThresholdSet(threshold);
    }

    /*───────────────────────────── ORACLE MANAGEMENT ─────────────────────────────*/
    function setOracle(string calldata symbol, address feedAddress) external onlyDAO {
        require(feedAddress != address(0), "Invalid feed address");

        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint8 decimals = feed.decimals();
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));

        oracles[symbolHash].push(OracleFeed(feed, decimals, true, block.timestamp));
        trackedAssets.push(symbolHash);

        emit OracleUpdated(symbolHash, feedAddress, decimals);
    }

    function removeOracle(string calldata symbol) external onlyDAO {
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        require(oracles[symbolHash].length > 0, "Oracle not found");
        delete oracles[symbolHash];
        emit OracleRemoved(symbolHash);
    }

    /*───────────────────────────── PRICE FUNCTIONS ─────────────────────────────*/
    function getPrice(string calldata symbol) external view returns (uint256) {
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        require(oracles[symbolHash].length > 0, "Oracle not found");
        return getLatestPrice(symbolHash);
    }

    function getLatestPrice(bytes32 symbolHash) internal view returns (uint256) {
        OracleFeed memory latestFeed = oracles[symbolHash][oracles[symbolHash].length - 1];
        (, int256 answer,,,) = latestFeed.feed.latestRoundData();
        uint256 normalized = uint256(answer) * 10**(18 - latestFeed.decimals);
        return normalized;
    }

    function checkPriceChange(bytes32 symbolHash, uint256 oldPrice) internal view returns (bool) {
        uint256 latestPrice = getLatestPrice(symbolHash);
        uint256 changePercentage = ((latestPrice - oldPrice) * 100) / oldPrice;
        return changePercentage >= priceUpdateThreshold;
    }

    function trackPriceChange(bytes32 symbolHash) internal {
        uint256 oldPrice = getLatestPrice(symbolHash);
        if (checkPriceChange(symbolHash, oldPrice)) {
            emit PriceThresholdTriggered(symbolHash, oldPrice);
        }
    }

    /*───────────────────────────── ERC2771Context OVERRIDES ─────────────────────────────*/
    function _msgSender() internal view override(ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}

