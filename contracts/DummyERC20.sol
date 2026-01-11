// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*───────────────────────────── CONTRACT ─────────────────────────────*/
/// @title DummyERC20 — Test-only ERC20 for simulation and local flows
/// @notice MUST NOT be used in production mint, swap, vault, or oracle flows
contract DummyERC20 is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Explicit on-chain test-only marker
    bool public immutable IS_TEST_TOKEN;

    /// @notice Optional human-readable purpose
    string public constant PURPOSE = "TEST_ONLY / NON_PRODUCTION";

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC20(name, symbol) {
        require(admin != address(0), "DummyERC20: zero admin");

        IS_TEST_TOKEN = true;

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    /*───────────────────────────── MINTING ─────────────────────────────*/
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /*───────────────────────────── PAUSING ─────────────────────────────*/
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /*───────────────────────────── TRANSFER GUARD ─────────────────────────────*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!paused(), "DummyERC20: paused");
        super._beforeTokenTransfer(from, to, amount);
    }
}

