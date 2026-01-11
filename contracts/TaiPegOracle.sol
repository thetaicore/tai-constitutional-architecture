// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface ITAI {
    function getFrequencyScore(address user) external view returns (uint256);
}

/// @notice Ultra-Minimal TaiPegOracle — Phase0 Bootstrap
/// @dev LayerZero integration deferred; Phase1 wiring required
abstract contract TaiPegOracle is ERC2771Context {
    using Address for address;

    // ──────────────── EVENTS ────────────────
    event PegSet(
        bytes32 indexed unit,
        uint256 rateWad,
        string memo,
        bytes32 verifyingDocHash,
        bool isOfficialUSD,
        uint256 effectiveAt
    );
    event GovernorUpdated(address indexed newGovernor);
    event ArchiveAdded(uint256 indexed index, string title, string link);
    event InitializedPhase1(address taiCoin, address canonicalUSD, address tai);

    // ──────────────── STATE ────────────────
    address public governor;
    ITAI public tai;
    string[] public arweaveLinks;
    mapping(uint256 => string) public arweaveTitles;
    bytes32 public lastUnit;
    uint256 public lastRate;
    bool public lastIsOfficialUSD;
    IERC20 public taiCoin;
    IERC20 public canonicalUSD;
    bool public phase1Initialized;
    string public endpoint; // LayerZero endpoint stored, init deferred

    // ──────────────── MODIFIERS ────────────────
    modifier onlyGov() {
        require(_msgSender() == governor, "TaiPeg: not governor");
        _;
    }

    modifier onlyPhase1() {
        require(phase1Initialized, "TaiPeg: phase1 not initialized");
        _;
    }

    // ──────────────── CONSTRUCTOR ────────────────
    constructor(
        string memory _endpoint_,
        address _forwarder,
        address _governor,
        string memory _link,
        string memory _title,
        address _taiCoin,
        address _canonicalUSD,
        address _tai
    ) ERC2771Context(_forwarder) {
        require(_governor != address(0), "TaiPeg: zero governor");
        governor = _governor;
        endpoint = _endpoint_;

        if (_taiCoin != address(0)) {
            require(_taiCoin.isContract(), "TaiPeg: TaiCoin not deployed");
            taiCoin = IERC20(_taiCoin);
        }
        if (_canonicalUSD != address(0)) {
            require(_canonicalUSD.isContract(), "TaiPeg: USD not deployed");
            canonicalUSD = IERC20(_canonicalUSD);
        }
        if (_tai != address(0)) {
            require(_tai.isContract(), "TaiPeg: TAI not deployed");
            tai = ITAI(_tai);
        }

        // store a single archive link
        arweaveLinks.push(_link);
        arweaveTitles[0] = _title;
        emit ArchiveAdded(0, _title, _link);

        // Genesis 1:1 USD peg
        lastUnit = keccak256("USD");
        lastRate = 1e18;
        lastIsOfficialUSD = true;
        emit PegSet(lastUnit, lastRate, "Genesis official 1:1 USD peg", keccak256("GENESIS_PEG"), true, block.timestamp);
    }

    // ──────────────── PHASE1 INITIALIZATION ────────────────
    function initializePhase1(address _taiCoin, address _canonicalUSD, address _tai) external onlyGov {
        require(!phase1Initialized, "TaiPeg: already initialized");
        require(_taiCoin != address(0) && _taiCoin.isContract(), "TaiPeg: invalid TaiCoin");
        require(_canonicalUSD != address(0) && _canonicalUSD.isContract(), "TaiPeg: invalid USD");
        require(_tai != address(0) && _tai.isContract(), "TaiPeg: invalid TAI");

        taiCoin = IERC20(_taiCoin);
        canonicalUSD = IERC20(_canonicalUSD);
        tai = ITAI(_tai);

        phase1Initialized = true;
        emit InitializedPhase1(_taiCoin, _canonicalUSD, _tai);
    }

    // ──────────────── GOVERNANCE ────────────────
    function setGovernor(address _gov) external onlyGov {
        require(_gov != address(0), "TaiPeg: zero governor");
        governor = _gov;
        emit GovernorUpdated(_gov);
    }

    // ──────────────── PEG MANAGEMENT ────────────────
    function setPeg(bytes32 unit, uint256 rateWad, string memory memo, bytes32 docHash, bool isOfficialUSD) public onlyGov onlyPhase1 {
        require(rateWad > 0, "TaiPeg: zero rate");
        lastUnit = unit;
        lastRate = rateWad;
        lastIsOfficialUSD = isOfficialUSD;
        emit PegSet(unit, rateWad, memo, docHash, isOfficialUSD, block.timestamp);
    }

    /// META TRANSACTIONS OVERRIDES
    function _msgSender() internal view override returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}

/// @notice Deployable TaiPegOracle instance
contract TaiPegOracleInstance is TaiPegOracle {
    constructor(
        string memory _endpoint_,
        address _forwarder,
        address _governor,
        string memory _link,
        string memory _title,
        address _taiCoin,
        address _canonicalUSD,
        address _tai
    ) TaiPegOracle(_endpoint_, _forwarder, _governor, _link, _title, _taiCoin, _canonicalUSD, _tai) {}
}

