// 🔒 TAI CORE — ABSOLUTE CONTRACT SYNCHRONIZATION, ATTESTATION & DEPLOYMENT DIRECTIVE
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

interface ITai {
    function validateClaim(address user, uint256 amount) external view returns (bool);
}

/// @title TaiAirdropClaim — Claim TaiCoin based on retroactive resonance scores.
/// @notice Fully meta-tx compatible, reentrancy safe, cross-chain ready.
contract TaiAirdropClaim is Ownable, ReentrancyGuard, ERC2771Context {
    IERC20 public immutable taiCoin;
    bytes32 public merkleRoot;
    ITai public tai;

    mapping(address => bool) public hasClaimed;

    event Claimed(address indexed user, uint256 amount);
    event MerkleRootUpdated(bytes32 newRoot);
    event ClaimRecovered(address to, uint256 amount);

    constructor(
        address _taiCoin,
        bytes32 _merkleRoot,
        address _taiAddress,
        address _forwarder
    ) ERC2771Context(_forwarder) {
        require(_taiCoin != address(0), "TaiCoin address zero");
        require(_taiAddress != address(0), "TAI address zero");

        taiCoin = IERC20(_taiCoin);
        merkleRoot = _merkleRoot;
        tai = ITai(_taiAddress);
    }

    /*───────────────────────────── META-TX OVERRIDES ─────────────────────────────*/
    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(ERC2771Context, Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }

    /*───────────────────────────── ADMIN FUNCTIONS ─────────────────────────────*/
    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(_newRoot);
    }

    /*───────────────────────────── CLAIM FUNCTIONS ─────────────────────────────*/
    function claim(uint256 amount, bytes32[] calldata proof)
        external
        nonReentrant
    {
        address sender = _msgSender();
        require(!hasClaimed[sender], "Already claimed");

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        // Validate claim via TAI AI model for resonance scoring
        require(tai.validateClaim(sender, amount), "Claim not valid according to TAI");

        hasClaimed[sender] = true;
        require(taiCoin.transfer(sender, amount), "Transfer failed");

        emit Claimed(sender, amount);
    }

    /*───────────────────────────── EMERGENCY / RECOVERY ─────────────────────────────*/
    function recoverUnclaimed(address to) external onlyOwner nonReentrant {
        uint256 bal = taiCoin.balanceOf(address(this));
        require(taiCoin.transfer(to, bal), "Recover failed");
        emit ClaimRecovered(to, bal);
    }

    /*───────────────────────────── VIEW HELPERS ─────────────────────────────*/
    function hasUserClaimed(address user) external view returns (bool) {
        return hasClaimed[user];
    }
}

