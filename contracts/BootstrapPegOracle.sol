// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract BootstrapPegOracle {
    bool public genesisFinalized;
    bytes32 public merkleRoot;

    function isOfficialOneToOneUSD() external pure returns (bool) {
        return true;
    }

    function finalizeGenesis(bytes32 _root) external {
        merkleRoot = _root;
        genesisFinalized = true;
    }
}

