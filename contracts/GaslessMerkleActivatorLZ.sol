// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface ITaiVaultMerkleClaim {
    function claim(address claimant, uint256 amount, bytes32[] calldata proof) external;
}

interface ITAI {
    function validateActivation(address user, uint256 amount) external returns (bool);
}

interface ILayerZeroEndpoint {
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;
}

/**
 * @title GaslessMerkleActivatorLZ
 * @notice Gasless, signature-based Merkle activation gate for Tai genesis vaults with LayerZero integration
 * @dev ERC2771 meta-tx compatible, replay-safe, domain-separated. Forwarder immutable.
 */
contract GaslessMerkleActivatorLZ is Ownable, ReentrancyGuard, Pausable, ERC2771Context {
    using ECDSA for bytes32;

    /*───────────────────────────── STATE ─────────────────────────────*/
    ITaiVaultMerkleClaim public vault;
    ITAI public tai;
    ILayerZeroEndpoint public lzEndpoint;

    mapping(address => bool) public activated;
    mapping(address => uint256) public userNonces;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event Activated(address indexed user, uint256 amount, uint256 timestamp);
    event NonceUpdated(address indexed user, uint256 newNonce);
    event VaultUpdated(address indexed newVault);
    event TAIUpdated(address indexed newTAI);
    event EndpointUpdated(address indexed newEndpoint);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        address _lzEndpoint,
        address _vault,
        address _tai,
        address _forwarder
    ) ERC2771Context(_forwarder) {
        require(_lzEndpoint != address(0), "Endpoint zero");
        require(_vault != address(0), "Vault zero");
        require(_tai != address(0), "TAI zero");
        require(_forwarder != address(0), "Forwarder zero");

        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        vault = ITaiVaultMerkleClaim(_vault);
        tai = ITAI(_tai);
    }

    /*───────────────────────────── ADMIN CONTROLS ─────────────────────────────*/
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Vault zero");
        vault = ITaiVaultMerkleClaim(_vault);
        emit VaultUpdated(_vault);
    }

    function setTAI(address _tai) external onlyOwner {
        require(_tai != address(0), "TAI zero");
        tai = ITAI(_tai);
        emit TAIUpdated(_tai);
    }

    function setLZEndpoint(address _lzEndpoint) external onlyOwner {
        require(_lzEndpoint != address(0), "Endpoint zero");
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        emit EndpointUpdated(_lzEndpoint);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /*───────────────────────────── ACTIVATION LOGIC ─────────────────────────────*/
    function activate(
        address user,
        uint256 amount,
        bytes32[] calldata proof,
        bytes calldata signature
    ) external nonReentrant whenNotPaused {
        require(user != address(0), "Invalid user");
        require(amount > 0, "Zero amount");
        require(!activated[user], "Already activated");

        uint256 nonce = userNonces[user];

        bytes32 digest = keccak256(
            abi.encodePacked(user, amount, nonce, block.chainid, address(this))
        ).toEthSignedMessageHash();

        address signer = digest.recover(signature);
        require(signer == user, "Invalid signature");

        require(tai.validateActivation(user, amount), "Activation rejected by TAI");

        // Effects
        activated[user] = true;
        userNonces[user] = nonce + 1;

        // Interaction
        vault.claim(user, amount, proof);

        emit Activated(user, amount, block.timestamp);
        emit NonceUpdated(user, userNonces[user]);
    }

    /*───────────────────────────── VIEW HELPERS ─────────────────────────────*/
    function getNonce(address user) external view returns (uint256) {
        return userNonces[user];
    }

    /*───────────────────────────── ERC2771 OVERRIDES ─────────────────────────────*/
    function _msgSender() internal view override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(Context, ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}

