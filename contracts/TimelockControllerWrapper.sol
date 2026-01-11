// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 * @title TimelockControllerWrapper
 * @notice TimelockController with traceability metadata and a separate forwarder.
 */
contract TimelockControllerWrapper is TimelockController, ERC2771Context {

    // -----------------------------
    // Metadata
    // -----------------------------
    string public timelockVersion = "1.0.0";      // Version for traceability
    string public jurisdiction;                   // Jurisdiction for transparency and audits

    // -----------------------------
    // Events
    // -----------------------------
    event JurisdictionUpdated(string newJurisdiction);
    event TimelockVersionUpdated(string newVersion);

    // -----------------------------
    // Constructor
    // -----------------------------
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin,
        string memory _jurisdiction,
        address forwarder // Address of the ERC2771 forwarder contract
    )
        TimelockController(minDelay, proposers, executors, admin)  // Timelock Controller Initialization
        ERC2771Context(forwarder)  // ERC2771 Initialization (forwarder address)
    {
        jurisdiction = _jurisdiction;
    }

    // -----------------------------
    // Admin-only functions
    // -----------------------------
    function setJurisdiction(string memory newJurisdiction) external {
        require(_msgSender() == address(this), "Only Timelock can update jurisdiction");
        jurisdiction = newJurisdiction;
        emit JurisdictionUpdated(newJurisdiction);
    }

    function setTimelockVersion(string memory newVersion) external {
        require(hasRole(TIMELOCK_ADMIN_ROLE, _msgSender()), "Only admin can update version");
        timelockVersion = newVersion;
        emit TimelockVersionUpdated(newVersion);
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(TIMELOCK_ADMIN_ROLE, account);
    }

    // -----------------------------
    // ERC2771Context Overrides
    // -----------------------------
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

