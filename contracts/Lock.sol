// 🔒 TAI CORE — ABSOLUTE CONTRACT SYNCHRONIZATION, ATTESTATION & DEPLOYMENT DIRECTIVE
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TaiLock
 * @notice Timelocked wallet with DAO-controlled unlock adjustments for TaiCore ecosystem
 * @dev Preserves full original logic, adds DAO flexibility, traceable events, and meta-tx readiness
 */
contract TaiLock {
    uint256 public unlockTime;
    address payable public owner;
    address public dao;

    // -----------------------------
    // Events
    // -----------------------------
    event Withdrawal(uint256 amount, uint256 when);
    event UnlockTimeUpdated(uint256 newUnlockTime, address updatedBy);
    event OwnerUpdated(address newOwner);

    // -----------------------------
    // Modifiers
    // -----------------------------
    modifier onlyDAO() {
        require(msg.sender == dao, "TaiLock: Only DAO");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "TaiLock: Only owner");
        _;
    }

    // -----------------------------
    // Constructor
    // -----------------------------
    constructor(uint256 _unlockTime, address _dao) payable {
        require(block.timestamp < _unlockTime, "TaiLock: Unlock time must be in the future");
        unlockTime = _unlockTime;
        dao = _dao;
        owner = payable(msg.sender);
    }

    // -----------------------------
    // DAO Controls
    // -----------------------------
    /**
     * @notice Allows DAO to adjust unlock time
     * @param _unlockTime New unlock timestamp
     */
    function setUnlockTime(uint256 _unlockTime) external onlyDAO {
        require(block.timestamp < _unlockTime, "TaiLock: Unlock time must be in the future");
        unlockTime = _unlockTime;
        emit UnlockTimeUpdated(_unlockTime, msg.sender);
    }

    /**
     * @notice Allows owner to transfer ownership of the locked funds
     * @param _newOwner New owner address
     */
    function setOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "TaiLock: Owner cannot be zero address");
        owner = _newOwner;
        emit OwnerUpdated(_newOwner);
    }

    // -----------------------------
    // Withdrawals
    // -----------------------------
    /**
     * @notice Withdraw funds after unlock time
     */
    function withdraw() external onlyOwner {
        require(block.timestamp >= unlockTime, "TaiLock: Cannot withdraw yet");

        uint256 balance = address(this).balance;
        emit Withdrawal(balance, block.timestamp);

        owner.transfer(balance);
    }

    // -----------------------------
    // Read Helpers
    // -----------------------------
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isUnlocked() external view returns (bool) {
        return block.timestamp >= unlockTime;
    }

    // -----------------------------
    // Future-Proof Notes
    // -----------------------------
    // - Can be upgraded for ERC2771Context to accept meta-transactions
    // - Can integrate LayerZero cross-chain triggers for DAO-controlled unlocks
}

