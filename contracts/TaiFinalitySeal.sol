// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    TAI FINALITY SEAL

    SYSTEM ROLE:
    - Canonical irreversibility anchor
    - Explicit finality recorder
    - Epoch-aware historical truth spine

    DESIGN PRINCIPLES:
    - Append-only
    - Non-revocable
    - Non-governing
    - Non-upgradeable
    - Deterministic

    THIS CONTRACT:
    - Does NOT grant authority
    - Does NOT alter protocol execution
    - Does NOT enforce logic
    - Does NOT resolve disputes
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaiFinalitySeal is Ownable {

    /*═══════════════════════════════════════════════════════════════
                                ENUMS
    ═══════════════════════════════════════════════════════════════*/

    enum FinalityDomain {
        UNDEFINED,
        ORACLE_RESOLUTION,
        AI_ADJUDICATION,
        CLAIM_FINALIZATION,
        GOVERNANCE_OUTCOME,
        EPOCH_CLOSURE,
        MERKLE_ROOT_COMMITMENT,
        CROSS_CHAIN_STATE,
        SYSTEM_ASSERTION,
        CUSTOM
    }

    /*═══════════════════════════════════════════════════════════════
                                STRUCTS
    ═══════════════════════════════════════════════════════════════*/

    struct FinalityRecord {
        bytes32 sealId;
        FinalityDomain domain;
        address sourceContract;
        uint256 epoch;
        uint256 sealedAt;
        bytes32 dataHash;
        string description;
    }

    /*═══════════════════════════════════════════════════════════════
                                STORAGE
    ═══════════════════════════════════════════════════════════════*/

    uint256 public totalSeals;

    // sealId => FinalityRecord
    mapping(bytes32 => FinalityRecord) private seals;

    // epoch => sealIds
    mapping(uint256 => bytes32[]) private epochSeals;

    /*═══════════════════════════════════════════════════════════════
                                EVENTS
    ═══════════════════════════════════════════════════════════════*/

    event FinalitySealed(
        bytes32 indexed sealId,
        FinalityDomain indexed domain,
        address indexed sourceContract,
        uint256 epoch,
        bytes32 dataHash
    );

    /*═══════════════════════════════════════════════════════════════
                            CONSTRUCTOR
    ═══════════════════════════════════════════════════════════════*/

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Invalid owner");
        _transferOwnership(initialOwner);
    }

    /*═══════════════════════════════════════════════════════════════
                        FINALITY SEALING LOGIC
    ═══════════════════════════════════════════════════════════════*/

    function sealFinality(
        FinalityDomain domain,
        address sourceContract,
        uint256 epoch,
        bytes32 dataHash,
        string calldata description
    ) external onlyOwner returns (bytes32 sealId) {
        require(sourceContract != address(0), "Invalid source");
        require(dataHash != bytes32(0), "Invalid data hash");

        sealId = keccak256(
            abi.encode(
                domain,
                sourceContract,
                epoch,
                dataHash,
                block.timestamp,
                totalSeals
            )
        );

        require(seals[sealId].sealedAt == 0, "Seal already exists");

        seals[sealId] = FinalityRecord({
            sealId: sealId,
            domain: domain,
            sourceContract: sourceContract,
            epoch: epoch,
            sealedAt: block.timestamp,
            dataHash: dataHash,
            description: description
        });

        totalSeals += 1;
        epochSeals[epoch].push(sealId);

        emit FinalitySealed(
            sealId,
            domain,
            sourceContract,
            epoch,
            dataHash
        );
    }

    /*═══════════════════════════════════════════════════════════════
                            VIEW FUNCTIONS
    ═══════════════════════════════════════════════════════════════*/

    function getSeal(bytes32 sealId)
        external
        view
        returns (FinalityRecord memory)
    {
        require(seals[sealId].sealedAt != 0, "Seal not found");
        return seals[sealId];
    }

    function getSealsByEpoch(uint256 epoch)
        external
        view
        returns (bytes32[] memory)
    {
        return epochSeals[epoch];
    }

    function isSealed(bytes32 sealId)
        external
        view
        returns (bool)
    {
        return seals[sealId].sealedAt != 0;
    }

    function sealCountForEpoch(uint256 epoch)
        external
        view
        returns (uint256)
    {
        return epochSeals[epoch].length;
    }
}

