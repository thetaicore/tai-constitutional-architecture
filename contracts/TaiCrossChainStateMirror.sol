// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    TAI CROSS-CHAIN STATE MIRROR

    SYSTEM ROLE:
    - Observational mirror for cross-chain attestations
    - Non-enforcing, non-governing, append-only
    - Canonical record of what was observed across chains

    THIS CONTRACT:
    - Does NOT gate execution
    - Does NOT validate correctness
    - Does NOT assert authority
    - Does NOT reconcile disputes
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaiCrossChainStateMirror is Ownable {

    /*═══════════════════════════════════════════════════════════════
                                ENUMS
    ═══════════════════════════════════════════════════════════════*/

    enum AttestationDomain {
        UNDEFINED,
        ORACLE_STATE,
        VAULT_STATE,
        CLAIM_STATE,
        GOVERNANCE_STATE,
        AI_STATE,
        FINALITY_STATE,
        EPOCH_STATE,
        CUSTOM
    }

    /*═══════════════════════════════════════════════════════════════
                                STRUCTS
    ═══════════════════════════════════════════════════════════════*/

    struct CrossChainAttestation {
        bytes32 attestationId;
        AttestationDomain domain;
        uint256 sourceChainId;
        address sourceContract;
        uint256 epoch;
        bytes32 stateHash;
        uint256 observedAt;
        string description;
    }

    /*═══════════════════════════════════════════════════════════════
                                STORAGE
    ═══════════════════════════════════════════════════════════════*/

    uint256 public totalAttestations;

    // attestationId => CrossChainAttestation
    mapping(bytes32 => CrossChainAttestation) private attestations;

    // epoch => attestationIds
    mapping(uint256 => bytes32[]) private epochAttestations;

    // sourceChainId => attestationIds
    mapping(uint256 => bytes32[]) private chainAttestations;

    /*═══════════════════════════════════════════════════════════════
                                EVENTS
    ═══════════════════════════════════════════════════════════════*/

    event CrossChainStateObserved(
        bytes32 indexed attestationId,
        AttestationDomain indexed domain,
        uint256 indexed sourceChainId,
        address sourceContract,
        uint256 epoch,
        bytes32 stateHash
    );

    /*═══════════════════════════════════════════════════════════════
                            CONSTRUCTOR
    ═══════════════════════════════════════════════════════════════*/

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Invalid owner");
        _transferOwnership(initialOwner);
    }

    /*═══════════════════════════════════════════════════════════════
                    OBSERVATIONAL RECORDING LOGIC
    ═══════════════════════════════════════════════════════════════*/

    function recordAttestation(
        AttestationDomain domain,
        uint256 sourceChainId,
        address sourceContract,
        uint256 epoch,
        bytes32 stateHash,
        string calldata description
    ) external onlyOwner returns (bytes32 attestationId) {
        require(domain != AttestationDomain.UNDEFINED, "Invalid domain");
        require(sourceChainId != 0, "Invalid chain");
        require(sourceContract != address(0), "Invalid source");
        require(stateHash != bytes32(0), "Invalid hash");

        attestationId = keccak256(
            abi.encode(
                domain,
                sourceChainId,
                sourceContract,
                epoch,
                stateHash,
                block.timestamp,
                totalAttestations
            )
        );

        require(attestations[attestationId].observedAt == 0, "Already recorded");

        attestations[attestationId] = CrossChainAttestation({
            attestationId: attestationId,
            domain: domain,
            sourceChainId: sourceChainId,
            sourceContract: sourceContract,
            epoch: epoch,
            stateHash: stateHash,
            observedAt: block.timestamp,
            description: description
        });

        totalAttestations += 1;

        epochAttestations[epoch].push(attestationId);
        chainAttestations[sourceChainId].push(attestationId);

        emit CrossChainStateObserved(
            attestationId,
            domain,
            sourceChainId,
            sourceContract,
            epoch,
            stateHash
        );
    }

    /*═══════════════════════════════════════════════════════════════
                            VIEW FUNCTIONS
    ═══════════════════════════════════════════════════════════════*/

    function getAttestation(bytes32 attestationId)
        external
        view
        returns (CrossChainAttestation memory)
    {
        require(attestations[attestationId].observedAt != 0, "Not found");
        return attestations[attestationId];
    }

    function getAttestationsByEpoch(uint256 epoch)
        external
        view
        returns (bytes32[] memory)
    {
        return epochAttestations[epoch];
    }

    function getAttestationsByChain(uint256 sourceChainId)
        external
        view
        returns (bytes32[] memory)
    {
        return chainAttestations[sourceChainId];
    }

    function isRecorded(bytes32 attestationId)
        external
        view
        returns (bool)
    {
        return attestations[attestationId].observedAt != 0;
    }
}
