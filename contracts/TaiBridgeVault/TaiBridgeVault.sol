// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IMerkleClaim {
    function claimableETH(address user, uint256 amount, bytes32[] calldata proof) external view returns (bool);
    function claimableERC20(address user, IERC20 token, uint256 amount, bytes32[] calldata proof) external view returns (bool);
}

interface ITaiAI {
    function validateBridge(address user, uint256 amount) external view returns (bool);
}

contract TaiBridgeVault is ERC2771Context {
    // ────────────── EVENTS ──────────────
    event Bridged(
        address indexed user,
        uint256 amount,
        string destination,
        string fiatCurrency,
        uint256 timestamp,
        bytes32 indexed intentHash,
        string vaultID,
        string jurisdiction
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ────────────── DEPLOYMENT STRUCT ──────────────
    struct VaultParams {
        address tai;
        address ai;
        address merkleClaim;
        address governor;
        address timelock;
        address dao;
        address layerZeroEndpoint;
        address pegOracle;
        address vaultMerkle;
        address airdropClaim;
        address coinSwap;
        address mintByResonance;
        address gaslessActivator;
        address gaslessActivatorLZ;
        address chainRouter;
        address crossChainMirror;
        address intuitionBridge;
        address vault;
        address phaseII;
        address redemptionVault;
        address merkleCore;
        address advancedUSD;
        address activatedUSD;
        address resonanceActivation;
        address vaultLpAdapter;
    }

    // ────────────── STATE ──────────────
    address public governor;
    address public timelock;
    address public dao;

    address public layerZeroEndpoint;
    address public pegOracle;
    address public vaultMerkle;
    address public airdropClaim;
    address public coinSwap;
    address public mintByResonance;
    address public gaslessActivator;
    address public gaslessActivatorLZ;
    address public chainRouter;
    address public crossChainMirror;
    address public intuitionBridge;
    address public vault;
    address public phaseII;
    address public redemptionVault;
    address public merkleCore;
    address public advancedUSD;
    address public activatedUSD;
    address public resonanceActivation;
    address public vaultLpAdapter;

    IERC20 public tai;
    IMerkleClaim public merkleClaimContract;
    ITaiAI public ai;

    string public targetCurrency;
    string public vaultJurisdiction;
    string public vaultVersion = "1.0";

    uint256 public cooldownPeriod;
    uint256 public lastBridgeTime;

    // ────────────── MODIFIERS ──────────────
    modifier onlyGov() {
        require(_msgSender() == governor, "Not governor");
        _;
    }

    modifier cooldownCheck() {
        require(block.timestamp >= lastBridgeTime + cooldownPeriod, "Cooldown not met");
        _;
    }

    // ────────────── CONSTRUCTOR ──────────────
    constructor(VaultParams memory p, string memory _targetCurrency, address _forwarder) ERC2771Context(_forwarder) {
        require(p.tai != address(0), "Invalid TaiCoin");
        require(p.ai != address(0), "Invalid TaiAI");
        require(p.merkleClaim != address(0), "Invalid MerkleClaim");
        require(p.governor != address(0), "Invalid Governor");

        tai = IERC20(p.tai);
        ai = ITaiAI(p.ai);
        merkleClaimContract = IMerkleClaim(p.merkleClaim);

        governor = p.governor;
        timelock = p.timelock;
        dao = p.dao;

        layerZeroEndpoint = p.layerZeroEndpoint;
        pegOracle = p.pegOracle;
        vaultMerkle = p.vaultMerkle;
        airdropClaim = p.airdropClaim;
        coinSwap = p.coinSwap;
        mintByResonance = p.mintByResonance;
        gaslessActivator = p.gaslessActivator;
        gaslessActivatorLZ = p.gaslessActivatorLZ;
        chainRouter = p.chainRouter;
        crossChainMirror = p.crossChainMirror;
        intuitionBridge = p.intuitionBridge;
        vault = p.vault;
        phaseII = p.phaseII;
        redemptionVault = p.redemptionVault;
        merkleCore = p.merkleCore;
        advancedUSD = p.advancedUSD;
        activatedUSD = p.activatedUSD;
        resonanceActivation = p.resonanceActivation;
        vaultLpAdapter = p.vaultLpAdapter;

        targetCurrency = _targetCurrency;
    }

    // ────────────── GOVERNOR FUNCTIONS ──────────────
    function setCooldown(uint256 _seconds) external onlyGov { cooldownPeriod = _seconds; }
    function setJurisdiction(string memory _jurisdiction) external onlyGov { vaultJurisdiction = _jurisdiction; }
    function transferGovernance(address newGovernor) external onlyGov {
        require(newGovernor != address(0), "Zero address");
        emit OwnershipTransferred(governor, newGovernor);
        governor = newGovernor;
    }

    // ────────────── BRIDGE LOGIC ──────────────
    function bridgeToFiat(uint256 amount, string memory destination, bytes32[] calldata proof) external cooldownCheck {
        require(amount > 0, "Amount must >0");
        require(
            merkleClaimContract.claimableETH(_msgSender(), amount, proof) ||
            merkleClaimContract.claimableERC20(_msgSender(), tai, amount, proof),
            "Invalid Merkle proof"
        );
        require(ai.validateBridge(_msgSender(), amount), "TAI AI validation failed");

        lastBridgeTime = block.timestamp;
        bytes32 intentHash = keccak256(abi.encodePacked(_msgSender(), amount, destination, block.timestamp));
        emit Bridged(_msgSender(), amount, destination, targetCurrency, block.timestamp, intentHash, "TaiBridgeVault", vaultJurisdiction);
    }

    // ────────────── EMERGENCY FUNCTIONS ──────────────
    function emergencyWithdrawERC20(IERC20 token, address to, uint256 amount) external onlyGov {
        require(to != address(0), "Invalid address");
        require(token.transfer(to, amount), "Transfer failed");
    }

    function emergencyWithdrawETH(address payable to, uint256 amount) external onlyGov {
        require(to != address(0), "Invalid address");
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    // ────────────── VIEW FUNCTIONS ──────────────
    function getVaultDetails() external view returns (address, string memory, string memory, string memory) {
        return (address(tai), targetCurrency, vaultJurisdiction, vaultVersion);
    }

    // ────────────── ERC2771 OVERRIDES ──────────────
    function _msgSender() internal view override(ERC2771Context) returns (address) { return ERC2771Context._msgSender(); }
    function _msgData() internal view override(ERC2771Context) returns (bytes calldata) { return ERC2771Context._msgData(); }
    function _contextSuffixLength() internal view override(ERC2771Context) returns (uint256) { return ERC2771Context._contextSuffixLength(); }
}

