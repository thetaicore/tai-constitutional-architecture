// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface ITaiVault {
    function mint(address to, uint256 amount) external;
}

/**
 * @title TaiChainRouter
 * @notice Handles cross-chain syncs and token distribution via LayerZero.
 * @dev Fully ERC2771Context + ReentrancyGuard + DAO-governed
 */
contract TaiChainRouter is NonblockingLzApp, ERC2771Context, ReentrancyGuard {
    ITaiVault public vault;
    uint256 public dynamicFeeRate = 100; // 1%
    address public dao;

    // ───────────────────────────── EVENTS ─────────────────────────────
    event SyncReceived(address indexed user, uint256 amount, uint16 fromChain, uint256 fee);
    event SyncSent(address indexed user, uint256 amount, uint16 toChain, uint256 fee);
    event FeeRateUpdated(uint256 newFeeRate);
    event VaultUpdated(address newVault);
    event DAOUpdated(address newDAO);

    // ───────────────────────────── MODIFIERS ─────────────────────────────
    modifier onlyDAO() {
        require(_msgSender() == dao, "Not authorized DAO");
        _;
    }

    // ───────────────────────────── CONSTRUCTOR ─────────────────────────────
    constructor(
        address _lzEndpoint,
        address _vault,
        address _dao,
        address _forwarder
    ) NonblockingLzApp(_lzEndpoint) ERC2771Context(_forwarder) {
        require(_vault != address(0), "Vault address zero");
        require(_dao != address(0), "DAO address zero");

        vault = ITaiVault(_vault);
        dao = _dao;
    }

    // ───────────────────────────── ERC2771 META-TX OVERRIDES ─────────────────────────────
    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(ERC2771Context, Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }

    // ───────────────────────────── DAO / ADMIN FUNCTIONS ─────────────────────────────
    function setDynamicFeeRate(uint256 newFeeRate) external onlyDAO {
        dynamicFeeRate = newFeeRate;
        emit FeeRateUpdated(newFeeRate);
    }

    function setVault(address newVault) external onlyDAO {
        require(newVault != address(0), "Vault cannot be zero");
        vault = ITaiVault(newVault);
        emit VaultUpdated(newVault);
    }

    function setDAO(address newDAO) external onlyDAO {
        require(newDAO != address(0), "DAO cannot be zero");
        dao = newDAO;
        emit DAOUpdated(newDAO);
    }

    // ───────────────────────────── CROSS-CHAIN FUNCTIONS ─────────────────────────────
    function sendVaultSync(
        uint16 _dstChainId,
        address user,
        uint256 amount
    ) external payable nonReentrant {
        require(user != address(0), "Invalid user");
        require(amount > 0, "Amount must be > 0");

        bytes memory payload = abi.encode(user, amount);
        uint256 fee = calculateSyncFee(payload.length);

        _lzSend(
            _dstChainId,           // uint16: destination chain
            payload,               // bytes: payload
            payable(_msgSender()), // refund address
            address(0),            // ZRO payment address
            bytes(""),             // adapterParams
            msg.value              // native fee
        );

        emit SyncSent(user, amount, _dstChainId, fee);
    }

    function calculateSyncFee(uint256 payloadLength) public view returns (uint256) {
        return (payloadLength * dynamicFeeRate) / 10_000;
    }

    // ───────────────────────────── LAYERZERO RECEIVE ─────────────────────────────
    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory,
        uint64,
        bytes memory payload
    ) internal override nonReentrant {
        (address user, uint256 amount) = abi.decode(payload, (address, uint256));
        require(user != address(0), "Invalid user");
        require(amount > 0, "Invalid amount");

        uint256 fee = calculateSyncFee(payload.length);
        vault.mint(user, amount - fee);

        emit SyncReceived(user, amount, srcChainId, fee);
    }

    // ───────────────────────────── EMERGENCY WITHDRAW ─────────────────────────────
    function withdrawFees(address to, uint256 amount) external onlyDAO nonReentrant {
        require(to != address(0), "Invalid recipient");
        payable(to).transfer(amount);
    }
}

