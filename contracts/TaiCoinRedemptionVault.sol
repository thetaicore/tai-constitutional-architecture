// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface ITAI {
    function validateRedemption(address user, uint256 taiAmount) external returns (bool);
}

/*───────────────────────────── CONTRACT ─────────────────────────────*/
/// @title TaiCoinRedemptionVault — Gasless, AI-validated TAI → USDC redemption vault
/// @notice Fully ERC2771-compatible, governance-controlled, with emergency pause
contract TaiCoinRedemptionVault is
    ERC2771Context,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    IERC20 public taiCoin;
    IERC20 public usdc;
    ITAI public tai;

    uint256 public constant RATE = 1e18; // 1 TAI = 1 USDC (18-decimal normalized)
    uint256 public maxRedemptionLimit;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event Redeemed(
        address indexed user,
        uint256 taiAmount,
        uint256 usdcAmount,
        uint256 timestamp
    );

    event RedemptionLimitUpdated(uint256 newLimit);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        address _taiCoin,
        address _usdc,
        address _governor,
        address _tai,
        uint256 _maxRedemptionLimit,
        address _forwarder
    )
        ERC2771Context(_forwarder)
        Ownable() // ⚡ OpenZeppelin v5+ pattern, no argument
    {
        require(_taiCoin != address(0), "TAI addr zero");
        require(_usdc != address(0), "USDC addr zero");
        require(_governor != address(0), "Gov zero");
        require(_tai != address(0), "TAI address zero");

    // Set governor manually since Ownable() no longer takes constructor args
        transferOwnership(_governor);

        taiCoin = IERC20(_taiCoin);
        usdc = IERC20(_usdc);
        tai = ITAI(_tai);
        maxRedemptionLimit = _maxRedemptionLimit;
    }

    /*───────────────────────────── REDEMPTION LOGIC ─────────────────────────────*/
    function redeem(uint256 taiAmount)
        external
        nonReentrant
        whenNotPaused
    {
        address sender = _msgSender();

        require(taiAmount > 0, "Zero amount");
        require(taiAmount <= maxRedemptionLimit, "Exceeds redemption limit");

        // AI validation
        require(
            tai.validateRedemption(sender, taiAmount),
            "Redemption not approved by TAI"
        );

        // Pull TAI from user
        require(
            taiCoin.transferFrom(sender, address(this), taiAmount),
            "TAI transfer failed"
        );

        // Normalize: 18 → 6 decimals for USDC
        uint256 usdcAmount = taiAmount / 1e12;

        require(
            usdc.balanceOf(address(this)) >= usdcAmount,
            "Insufficient USDC liquidity"
        );

        require(
            usdc.transfer(sender, usdcAmount),
            "USDC transfer failed"
        );

        emit Redeemed(sender, taiAmount, usdcAmount, block.timestamp);
    }

    /*───────────────────────────── GOVERNANCE ─────────────────────────────*/
    function setRedemptionLimit(uint256 newLimit) external onlyOwner {
        maxRedemptionLimit = newLimit;
        emit RedemptionLimitUpdated(newLimit);
    }

    function withdrawUSDC(uint256 amount) external onlyOwner {
        require(usdc.transfer(owner(), amount), "USDC transfer failed");
    }

    function withdrawTAI(uint256 amount) external onlyOwner {
        require(taiCoin.transfer(owner(), amount), "TAI transfer failed");
    }

    /*───────────────────────────── EMERGENCY CONTROLS ─────────────────────────────*/
    function emergencyPause() external onlyOwner {
        _pause();
    }

    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    /*───────────────────────────── ERC2771 CONTEXT OVERRIDES ─────────────────────────────*/
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength()
        internal
        view
        override(Context, ERC2771Context)
        returns (uint256)
    {
        return ERC2771Context._contextSuffixLength();
    }
}

