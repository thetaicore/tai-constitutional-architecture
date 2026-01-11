// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Dummy LP placeholder for TaiVaultLiquidityAdapter bootstrap
/// @notice Implements minimal UniswapV2Pair interface
contract DummyLP {
    function token0() external pure returns (address) {
        return address(0);
    }

    function token1() external pure returns (address) {
        return address(0);
    }

    function getReserves()
        external
        pure
        returns (uint112, uint112, uint32)
    {
        return (0, 0, 0);
    }
}

