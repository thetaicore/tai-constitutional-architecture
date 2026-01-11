// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol"; 

interface ITAI {
    function evaluateMintingDecision(address to, uint256 amount) external returns (bool);
    function getUserFrequency(address user) external view returns (uint256);
}

/// @title AdvancedUSDStablecoin — TaiCore-compliant stablecoin
contract AdvancedUSDStablecoin is ERC20, ERC20Burnable, AccessControl, Pausable {

    // -----------------------------
    // Roles
    // -----------------------------
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ANONYMOUS_MINTER_ROLE = keccak256("ANONYMOUS_MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // -----------------------------
    // Core State
    // -----------------------------
    uint256 private _maxSupply;
    ITAI public tai;
    address public dao;
    string public tokenVersion = "1.0.0";
    string public jurisdiction;

    // -----------------------------
    // Events
    // -----------------------------
    event AnonymousMint(address indexed to, uint256 amount);
    event MintDecisionEvaluated(address indexed to, uint256 amount, bool allowed);
    event TokenVersionUpdated(string newVersion);
    event JurisdictionUpdated(string newJurisdiction);
    event DAOUpdated(address indexed newDAO);

    // -----------------------------
    // Constructor
    // -----------------------------
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address _tai,
        address _dao
    ) ERC20(name_, symbol_) {
        require(_tai != address(0), "TAI address cannot be zero");
        require(_dao != address(0), "DAO address cannot be zero");

        _maxSupply = maxSupply_;
        tai = ITAI(_tai);
        dao = _dao;

        // Grant all roles to deployer initially
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(ANONYMOUS_MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    // -----------------------------
    // Metadata / Governance
    // -----------------------------
    function setTokenVersion(string memory version) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenVersion = version;
        emit TokenVersionUpdated(version);
    }

    function setJurisdiction(string memory _jurisdiction) external onlyRole(DEFAULT_ADMIN_ROLE) {
        jurisdiction = _jurisdiction;
        emit JurisdictionUpdated(_jurisdiction);
    }

    function setDAO(address _dao) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_dao != address(0), "DAO cannot be zero");
        dao = _dao;
        emit DAOUpdated(_dao);
    }

    // -----------------------------
    // Supply
    // -----------------------------
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    // -----------------------------
    // Minting
    // -----------------------------
    function mint(address to, uint256 amount) external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender) || msg.sender == dao, "Not authorized");
        require(totalSupply() + amount <= _maxSupply, "Max supply exceeded");

        bool allowed = tai.evaluateMintingDecision(to, amount);
        emit MintDecisionEvaluated(to, amount, allowed);
        require(allowed, "Minting not approved by TAI");

        _mint(to, amount);
    }

    function anonymousMint(address to, uint256 amount) external whenNotPaused {
        require(hasRole(ANONYMOUS_MINTER_ROLE, msg.sender) || msg.sender == dao, "Not authorized");
        require(totalSupply() + amount <= _maxSupply, "Max supply exceeded");

        bool allowed = tai.evaluateMintingDecision(to, amount);
        emit MintDecisionEvaluated(to, amount, allowed);
        require(allowed, "Minting not approved by TAI");

        _mint(to, amount);
        emit AnonymousMint(to, amount);
    }

    // -----------------------------
    // Pausing
    // -----------------------------
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // -----------------------------
    // Burn
    // -----------------------------
    function burn(uint256 amount) public override whenNotPaused {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override whenNotPaused {
        super.burnFrom(account, amount);
    }

    // -----------------------------
    // Hook for pause enforcement
    // -----------------------------
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

