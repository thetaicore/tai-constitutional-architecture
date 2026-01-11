// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// @title TaiVaultLiquidityAdapter
/// @notice Adapter for LP state; compatible with dummy LP placeholder
contract TaiVaultLiquidityAdapter is Ownable {

    IUniswapV2Pair public lpToken;
    address public token0;
    address public token1;

    event LPRegistered(address indexed lpToken);

    /// @param _lpToken real LP or DummyLP placeholder
    constructor(address _lpToken) {
        require(_lpToken != address(0), "Must pass a placeholder or real LP");
        lpToken = IUniswapV2Pair(_lpToken);
        token0 = lpToken.token0();
        token1 = lpToken.token1();
        emit LPRegistered(_lpToken);
    }

    /// @notice Returns LP reserves
    function getReserves() external view returns (uint112 r0, uint112 r1, uint32 ts) {
        return lpToken.getReserves();
    }

    /// @notice Returns LP token addresses
    function getLPInfo() external view returns (address, address) {
        return (token0, token1);
    }

    /// @notice Update LP to real LP
    function registerLP(address _lpToken) external onlyOwner {
        require(_lpToken != address(0), "Invalid LP token");
        lpToken = IUniswapV2Pair(_lpToken);
        token0 = lpToken.token0();
        token1 = lpToken.token1();
        emit LPRegistered(_lpToken);
    }

    /// @notice Refresh token0/token1 from current LP
    function refreshLPInfo() external onlyOwner {
        token0 = lpToken.token0();
        token1 = lpToken.token1();
    }
}

