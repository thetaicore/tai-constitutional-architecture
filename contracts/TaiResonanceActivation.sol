// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface ITAI {
    function validateResonanceActivation(address user, uint256 amount) external returns (bool);
}

/*───────────────────────────── CONTRACT ─────────────────────────────*/
/// @title TaiResonanceActivation — AI & Merkle-verified resonance activation system
/// @notice Tracks activation, ensures single-use per user, integrates TAI validation
contract TaiResonanceActivation is ERC2771Context, Ownable, ReentrancyGuard, Pausable {
    /*───────────────────────────── CORE STATE ─────────────────────────────*/
    bytes32 public merkleRoot;
    uint256 public totalActivatedSupply;

    mapping(address => bool) public hasActivated;
    mapping(address => uint256) public resonanceBalance;

    // Optional symbolic denomination
    string public constant NAME = "Tai Sovereign Resonance Unit";
    string public constant SYMBOL = "TSRU";
    uint8  public constant DECIMALS = 18;

    /*───────────────────────────── GOVERNANCE ─────────────────────────────*/
    address public dao;
    ITAI public tai;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event ResonanceActivated(
        address indexed holder,
        uint256 amount,
        bytes32 indexed leaf,
        uint256 timestamp
    );
    event MerkleRootUpdated(bytes32 newRoot);
    event DAOUpdated(address newDAO);
    event TAIIntegrationUpdated(address newTAI);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        bytes32 _merkleRoot,
        address _dao,
        address _tai,
        address _forwarder
    ) ERC2771Context(_forwarder) {
        require(_dao != address(0), "Invalid DAO address");
        require(_tai != address(0), "Invalid TAI address");

        merkleRoot = _merkleRoot;
        dao = _dao;
        tai = ITAI(_tai);
    }

    /*───────────────────────────── ADMIN FUNCTIONS ─────────────────────────────*/
    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(_newRoot);
    }

    function updateDAO(address _newDAO) external onlyOwner {
        require(_newDAO != address(0), "Invalid DAO address");
        dao = _newDAO;
        emit DAOUpdated(_newDAO);
    }

    function updateTAI(address _newTAI) external onlyOwner {
        require(_newTAI != address(0), "Invalid TAI address");
        tai = ITAI(_newTAI);
        emit TAIIntegrationUpdated(_newTAI);
    }

    /*───────────────────────────── RESONANCE ACTIVATION ─────────────────────────────*/
    function activate(uint256 amount, bytes32[] calldata proof)
        external
        nonReentrant
        whenNotPaused
    {
        require(!hasActivated[_msgSender()], "Already activated");

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle proof");

        // Validate via TAI AI
        require(tai.validateResonanceActivation(_msgSender(), amount), "Activation not approved by TAI");

        // Record activation
        hasActivated[_msgSender()] = true;
        resonanceBalance[_msgSender()] = amount;
        totalActivatedSupply += amount;

        emit ResonanceActivated(_msgSender(), amount, leaf, block.timestamp);
    }

    /*───────────────────────────── READ FUNCTIONS ─────────────────────────────*/
    function balanceOf(address user) external view returns (uint256) {
        return resonanceBalance[user];
    }

    /*───────────────────────────── SECURITY / EMERGENCY ─────────────────────────────*/
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(_msgSender());
    }

    /*───────────────────────────── ERC2771Context OVERRIDES ─────────────────────────────*/
    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(Context, ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}

