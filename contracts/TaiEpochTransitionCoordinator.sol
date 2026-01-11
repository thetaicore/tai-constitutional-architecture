// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    TAI EPOCH TRANSITION COORDINATOR

    SYSTEM ROLE:
    - Canonical recorder of epoch transitions
    - Explicit declaration of system evolution boundaries
    - Non-mutative, non-governing, observational authority

    THIS CONTRACT:
    - Does NOT change behavior of other contracts
    - Does NOT enforce transitions
    - Does NOT gate execution
    - Does NOT rewrite historical state
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaiEpochTransitionCoordinator is Ownable {

    /*═══════════════════════════════════════════════════════════════
                                STRUCTS
    ═══════════════════════════════════════════════════════════════*/

    struct EpochTransition {
        uint256 fromEpoch;
        uint256 toEpoch;
        uint256 declaredAt;
        string rationale;
        bytes32 referenceHash;
    }

    /*═══════════════════════════════════════════════════════════════
                                STORAGE
    ═══════════════════════════════════════════════════════════════*/

    uint256 public currentEpoch;
    uint256 public totalTransitions;

    // transitionId => EpochTransition
    mapping(uint256 => EpochTransition) private transitions;

    // epoch => transitionIds
    mapping(uint256 => uint256[]) private epochTransitions;

    /*═══════════════════════════════════════════════════════════════
                                EVENTS
    ═══════════════════════════════════════════════════════════════*/

    event EpochTransitionDeclared(
        uint256 indexed transitionId,
        uint256 indexed fromEpoch,
        uint256 indexed toEpoch,
        bytes32 referenceHash
    );

    /*═══════════════════════════════════════════════════════════════
                            CONSTRUCTOR
    ═══════════════════════════════════════════════════════════════*/

    constructor(address initialOwner, uint256 genesisEpoch) {
        require(initialOwner != address(0), "Invalid owner");

        _transferOwnership(initialOwner);
        currentEpoch = genesisEpoch;
    }

    /*═══════════════════════════════════════════════════════════════
                        EPOCH TRANSITION LOGIC
    ═══════════════════════════════════════════════════════════════*/

    function declareEpochTransition(
        uint256 nextEpoch,
        string calldata rationale,
        bytes32 referenceHash
    ) external onlyOwner returns (uint256 transitionId) {
        require(nextEpoch > currentEpoch, "Epoch regression");
        require(referenceHash != bytes32(0), "Invalid reference");

        totalTransitions += 1;
        transitionId = totalTransitions;

        transitions[transitionId] = EpochTransition({
            fromEpoch: currentEpoch,
            toEpoch: nextEpoch,
            declaredAt: block.timestamp,
            rationale: rationale,
            referenceHash: referenceHash
        });

        epochTransitions[currentEpoch].push(transitionId);
        currentEpoch = nextEpoch;

        emit EpochTransitionDeclared(
            transitionId,
            transitions[transitionId].fromEpoch,
            nextEpoch,
            referenceHash
        );
    }

    /*═══════════════════════════════════════════════════════════════
                            VIEW FUNCTIONS
    ═══════════════════════════════════════════════════════════════*/

    function getTransition(uint256 transitionId)
        external
        view
        returns (EpochTransition memory)
    {
        require(
            transitionId > 0 && transitionId <= totalTransitions,
            "Invalid transition"
        );
        return transitions[transitionId];
    }

    function getTransitionsFromEpoch(uint256 epoch)
        external
        view
        returns (uint256[] memory)
    {
        return epochTransitions[epoch];
    }

    function latestTransition()
        external
        view
        returns (EpochTransition memory)
    {
        require(totalTransitions > 0, "No transitions");
        return transitions[totalTransitions];
    }
}
