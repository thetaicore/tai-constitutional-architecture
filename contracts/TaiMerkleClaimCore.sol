// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

interface ITAI {
    function validateClaim(address user, uint256 amount) external returns (bool);
}

/*───────────────────────────── CONTRACT ─────────────────────────────*/
/// @title TaiMerkleClaimCore — AI-validated Merkle claim system with ERC20 wrapper minting
/// @notice Handles single-use claims, TAI validation, and ERC20 wrapper minting
contract TaiMerkleClaimCore is ERC2771Context, Ownable, ReentrancyGuard {
    /*───────────────────────────── CORE STATE ─────────────────────────────*/
    bytes32 public merkleRoot;
    IMintableERC20 public wrapperToken;
    ITAI public tai;

    mapping(address => bool) public claimed;
    mapping(address => uint256) public activatedAmount;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event Activated(address indexed claimant, uint256 amount, bytes32 indexed merkleRoot);
    event MerkleRootUpdated(bytes32 newRoot);
    event WrapperTokenUpdated(address newToken);
    event TAIIntegrationUpdated(address newTAI);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(bytes32 _merkleRoot, address _tai, address _forwarder) ERC2771Context(_forwarder) {
        require(_tai != address(0), "Invalid TAI address");
        merkleRoot = _merkleRoot;
        tai = ITAI(_tai);
    }

    /*───────────────────────────── ADMIN FUNCTIONS ─────────────────────────────*/
    function setWrapperToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        wrapperToken = IMintableERC20(token);
        emit WrapperTokenUpdated(token);
    }

    function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit MerkleRootUpdated(newRoot);
    }

    function updateTAI(address _newTAI) external onlyOwner {
        require(_newTAI != address(0), "Invalid TAI address");
        tai = ITAI(_newTAI);
        emit TAIIntegrationUpdated(_newTAI);
    }

    /*───────────────────────────── ACTIVATION FUNCTION ─────────────────────────────*/
    function activate(uint256 amount, bytes32[] calldata proof)
        external
        nonReentrant
    {
        address sender = _msgSender();
        require(!claimed[sender], "Already activated");

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle proof");

        // TAI validation
        require(tai.validateClaim(sender, amount), "Claim not approved by TAI");

        claimed[sender] = true;
        activatedAmount[sender] = amount;

        // Mint wrapper ERC20 tokens
        wrapperToken.mint(sender, amount);

        emit Activated(sender, amount, merkleRoot);
    }

    /*───────────────────────────── READ FUNCTION ─────────────────────────────*/
    function balanceOf(address user) external view returns (uint256) {
        return activatedAmount[user];
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

