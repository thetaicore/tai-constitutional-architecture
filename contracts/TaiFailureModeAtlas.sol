// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    TAI FAILURE MODE ATLAS

    SYSTEM ROLE:
    - Canonical declaration of failure philosophy
    - Explicit recording of fail-open / fail-closed intent
    - Observational only, non-executive

    THIS CONTRACT:
    - Does NOT alter runtime behavior
    - Does NOT gate execution
    - Does NOT introduce safeguards
    - Does NOT change revert logic
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaiFailureModeAtlas is Ownable {

    /*═══════════════════════════════════════════════════════════════
                                ENUMS
    ═══════════════════════════════════════════════════════════════*/

    enum FailureMode {
        UNDEFINED,
        FAIL_OPEN,
        FAIL_CLOSED,
        HYBRID
    }

    enum SystemDomain {
        NONE,
        ORACLE_PIPELINE,
        AI_EVALUATION,
        CLAIM_PROCESSING,
        VAULT_WITHDRAWAL,
        CROSS_CHAIN_MESSAGING,
        GOVERNANCE_EXECUTION,
        FINALITY_RECORDING,
        OBSERVATIONAL_LAYER,
        CUSTOM
    }

    /*═══════════════════════════════════════════════════════════════
                                STRUCTS
    ═══════════════════════════════════════════════════════════════*/

    struct FailureDeclaration {
        SystemDomain domain;
        FailureMode mode;
        uint256 epoch;
        uint256 declaredAt;
        string rationale;
        bool immutableDeclaration;
    }

    /*═══════════════════════════════════════════════════════════════
                                STORAGE
    ═══════════════════════════════════════════════════════════════*/

    uint256 public totalDeclarations;

    // declarationId => FailureDeclaration
    mapping(uint256 => FailureDeclaration) private declarations;

    // domain => declarationIds
    mapping(SystemDomain => uint256[]) private domainDeclarations;

    /*═══════════════════════════════════════════════════════════════
                                EVENTS
    ═══════════════════════════════════════════════════════════════*/

    event FailureModeDeclared(
        uint256 indexed declarationId,
        SystemDomain indexed domain,
        FailureMode mode,
        uint256 epoch,
        bool immutableDeclaration
    );

    /*═══════════════════════════════════════════════════════════════
                            CONSTRUCTOR
    ═══════════════════════════════════════════════════════════════*/

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Invalid owner");
        _transferOwnership(initialOwner);
    }

    /*═══════════════════════════════════════════════════════════════
                    FAILURE MODE DECLARATION LOGIC
    ═══════════════════════════════════════════════════════════════*/

    function declareFailureMode(
        SystemDomain domain,
        FailureMode mode,
        uint256 epoch,
        bool immutableDeclaration,
        string calldata rationale
    ) external onlyOwner returns (uint256 declarationId) {
        require(domain != SystemDomain.NONE, "Invalid domain");
        require(mode != FailureMode.UNDEFINED, "Invalid mode");

        totalDeclarations += 1;
        declarationId = totalDeclarations;

        declarations[declarationId] = FailureDeclaration({
            domain: domain,
            mode: mode,
            epoch: epoch,
            declaredAt: block.timestamp,
            rationale: rationale,
            immutableDeclaration: immutableDeclaration
        });

        domainDeclarations[domain].push(declarationId);

        emit FailureModeDeclared(
            declarationId,
            domain,
            mode,
            epoch,
            immutableDeclaration
        );
    }

    /*═══════════════════════════════════════════════════════════════
                            VIEW FUNCTIONS
    ═══════════════════════════════════════════════════════════════*/

    function getDeclaration(uint256 declarationId)
        external
        view
        returns (FailureDeclaration memory)
    {
        require(
            declarationId > 0 && declarationId <= totalDeclarations,
            "Invalid declaration"
        );
        return declarations[declarationId];
    }

    function getDeclarationsForDomain(SystemDomain domain)
        external
        view
        returns (uint256[] memory)
    {
        return domainDeclarations[domain];
    }

    function latestDeclarationForDomain(SystemDomain domain)
        external
        view
        returns (FailureDeclaration memory)
    {
        uint256[] memory ids = domainDeclarations[domain];
        require(ids.length > 0, "No declarations for domain");
        return declarations[ids[ids.length - 1]];
    }

    function isDeclarationImmutable(uint256 declarationId)
        external
        view
        returns (bool)
    {
        require(
            declarationId > 0 && declarationId <= totalDeclarations,
            "Invalid declaration"
        );
        return declarations[declarationId].immutableDeclaration;
    }
}
