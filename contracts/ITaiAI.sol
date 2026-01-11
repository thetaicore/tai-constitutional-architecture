// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITaiAI {
    function processIntentSignal(
        address user,
        uint256 score,
        string calldata signalType
    ) external;

    function validateProposal(
        string calldata description,
        address target,
        bytes calldata callData,
        uint256 action
    ) external view returns (bool);

    function getMetaphysicalResonance(address user)
        external
        view
        returns (uint256);

    function validateResonanceScore(
        uint256 resonanceScore,
        address user
    ) external view returns (bool);

    function setBaseResonance(uint256 newBase) external;
    function setDAO(address newDAO) external;
}

