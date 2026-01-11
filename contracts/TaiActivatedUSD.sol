// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*───────────────────────────── CONTRACT ─────────────────────────────*/
/// @title TaiActivatedUSD — ERC20 wrapper fully aligned with TaiCore
/// @notice Supports MerkleCore minting, DAO governance, and traceability
contract TaiActivatedUSD is ERC20, Ownable {

    /*───────────────────────────── CORE STATE ─────────────────────────────*/
    address public merkleCore;      // Contract authorized to mint via Merkle activation
    address public dao;             // DAO address for governance control
    string public tokenVersion = "1.0.0";  // Version metadata for audit purposes
    string public jurisdiction;     // Optional legal/regulatory metadata

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event MerkleCoreUpdated(address indexed newCore);
    event DAOUpdated(address indexed newDAO);
    event TokenVersionUpdated(string newVersion);
    event JurisdictionUpdated(string newJurisdiction);
    event TokensMinted(address indexed to, uint256 amount, address indexed by);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor() ERC20("Tai Activated USD", "tUSD-A") {}

    /*───────────────────────────── GOVERNANCE / ADMIN FUNCTIONS ─────────────────────────────*/
    function setMerkleCore(address core) external onlyOwner {
        require(core != address(0), "Invalid MerkleCore address");
        merkleCore = core;
        emit MerkleCoreUpdated(core);
    }

    function setDAO(address _dao) external onlyOwner {
        require(_dao != address(0), "Invalid DAO address");
        dao = _dao;
        emit DAOUpdated(_dao);
    }

    function setTokenVersion(string memory version) external onlyOwner {
        tokenVersion = version;
        emit TokenVersionUpdated(version);
    }

    function setJurisdiction(string memory _jurisdiction) external onlyOwner {
        jurisdiction = _jurisdiction;
        emit JurisdictionUpdated(_jurisdiction);
    }

    /*───────────────────────────── MINTING FUNCTIONS ─────────────────────────────*/
    function mint(address to, uint256 amount) external {
        require(msg.sender == merkleCore || msg.sender == dao, "Not authorized");
        _mint(to, amount);
        emit TokensMinted(to, amount, msg.sender);
    }

    /*───────────────────────────── READ FUNCTIONS ─────────────────────────────*/
    function getMintAuthority() external view returns (address) {
        return merkleCore;
    }

    function getDAO() external view returns (address) {
        return dao;
    }
}

