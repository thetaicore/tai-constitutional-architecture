# Tai Constitutional Architecture

## A Live, Verifiable, Constraint-Based System for Governance, Value Custody, and Human–AI Coordination  
**Deployed on Ethereum Mainnet**

---

## 0. Reader Contract

This repository is intended to be read by:
- smart contract auditors
- protocol engineers
- governance designers
- AI safety researchers
- technically literate reviewers

This README is not marketing material.

It is a **system map**.

If you are looking for claims, skip this repository.  
If you are looking for structure, verification, and limits, continue.

---

## 1. What This System Is

This repository contains the **complete source, deployment scripts, and verification artifacts** for a **live Ethereum mainnet system** implementing a *constitutionally constrained architecture* for governance and value custody.

Key properties:

- **Live on Ethereum mainnet**
- **No privileged upgrade authority**
- **Artificial intelligence is advisory only**
- **Execution is delayed, scoped, and observable**
- **System history is non-erasive**
- **Intent is recorded separately from execution**

This system is already deployed.  
This repository exists to explain it.

---

## 2. What This System Is Not

To avoid category errors, this architecture is explicitly **not**:

- an autonomous AI treasury
- a self-upgrading protocol
- a discretionary multisig
- a governance token experiment
- a simulated framework

AI does **not**:
- hold keys
- move funds
- execute transactions
- bypass governance
- trigger upgrades

All execution requires human-originated, on-chain actions within predefined constraints.

---

## 3. Design Premise (From Whitepaper to Code)

The TaiCoin whitepaper establishes three non-negotiable premises:

1. **Meaning must outlive execution**
2. **Power must be constrained structurally, not ethically**
3. **History must never be rewritten**

This repository demonstrates how those premises are encoded directly into Solidity contracts and deployment topology.

The architecture does not rely on promises, operators, or policies.

It relies on **inability**.

---

## 4. System Architecture Overview

The system is divided into **five authority layers**.  
Each layer is prevented at the bytecode level from assuming the responsibilities of another.

┌───────────────────────────┐
│ Constitutional Layer      │  ← records intent, cannot act
├───────────────────────────┤
│ Temporal / Context Layer  │  ← manages epochs & delays
├───────────────────────────┤
│ Intelligence Layer        │  ← advisory signals only
├───────────────────────────┤
│ Governance Layer          │  ← delayed human decisions
├───────────────────────────┤
│ Execution Layer           │  ← narrowly scoped actions
└───────────────────────────┘

---

## 5. Constitutional Layer (Non-Executing)

### Purpose
To permanently record **why** the system exists and **what it is not allowed to do**.

### Properties
- No payable functions
- No external calls
- No delegatecall
- No upgrade hooks
- No execution authority

### Typical Responsibilities
- system invariants
- authority boundaries
- consent assumptions
- epoch definitions
- irreversibility markers

### Security Implication
Even total governance capture **cannot rewrite system intent**.

---

## 6. Temporal & Context Layer

### Purpose
To ensure **time, delay, and context** are enforced mechanically.

### Responsibilities
- proposal delays
- execution windows
- epoch transitions
- cross-chain observation references
- oracle aggregation

### Why This Matters
Most governance failures occur because *time is bypassed*.  
This layer makes bypassing time impossible.

---

## 7. Intelligence Layer (AI Advisory Only)

### Purpose
To introduce analytical intelligence **without authority**.

### Capabilities
- signal generation
- risk evaluation
- context synthesis
- recommendation publication

### Explicit Limitations
AI contracts:
- cannot call execution contracts
- cannot submit governance proposals
- cannot bypass delays
- cannot access vaults

### Architectural Principle
AI is treated as **a witness**, not an actor.

---

## 8. Governance Layer

### Purpose
To allow **human-directed change**, slowly and transparently.

### Properties
- explicit proposal scopes
- time-locked execution
- on-chain observability
- irreversible records

### What Governance Cannot Do
- perform instant actions
- erase history
- override constitutional constraints
- delegate authority to AI

Delay is not a weakness.  
Delay is a safety mechanism.

---

## 9. Execution Layer

### Purpose
To perform narrowly defined actions such as:
- asset transfers
- vault releases
- staking operations
- cross-chain messaging

### Properties
- minimal surface area
- replaceable implementations
- no embedded policy logic

Execution contracts are **tools**, not authorities.

---

## 10. Repository Structure

contracts/
constitutional/   ← intent & invariants
temporal/         ← epochs, delays
intelligence/     ← AI advisory logic
governance/       ← proposals & timelocks
vaults/           ← asset custody
execution/        ← narrow actions
crosschain/       ← LayerZero interfaces
interfaces/

scripts/
deploy/           ← deterministic deployments
verify/           ← Etherscan verification
registry/         ← address indexing

docs/
whitepaper/
threat-model/
audits/

diagrams/
architecture/
data-flow/
failure-modes/

This structure mirrors authority boundaries, not developer convenience.

---

## 11. Ethereum Mainnet Deployment

All core contracts are deployed on Ethereum mainnet.

Properties:
- bytecode verified
- source matches repository
- deployment scripts included
- no hidden upgrade keys
- no proxy admin backdoors

This repository functions as a **forensic record**.

---

## 12. Deployed Contract Addresses — Ethereum Mainnet

All contracts listed below are live on Ethereum mainnet, verified on Etherscan, and deployed using the scripts contained in this repository.
Addresses are grouped by architectural responsibility for audit clarity.

Governance & Authority

Governor (Canonical):
0x634f5A18A455EA8A8B6Ed9c34E6e8511037D12ee

Timelock Controller:
0x5612990241851F095DdC9bC17C909299395c2f1e

DAO Core:
0xDb11F930dBad67f9FdF2cBFf6d6D1905d819F64b

Council:
0xAd94c1F13265A014538b5D4E4A773d3B1E959A5a

Constitutional & System Integrity Layer

Tai Architecture Registry:
0xe0A527E7b8F0126eB1f7fbf285DEAd17D07e0a8c

Epoch Transition Coordinator:
0x61dAE84082F20A1C958Ab94fEadB55890D9444e6

Finality Seal:
0xBF915364B94F827d9f7D4e32a8AE6Ad3e87dAb84

Failure Mode Atlas:
0x86a712CAf2c34aB676E4B8191c5bFa0e92236db5

Consent Manifold:
0x7756D9157D20cd63713c79DCB493CA135eCd351C

Intelligence & Oracle Layer (Advisory-Only)

Tai AI Core:
0xBbE5D48B5E2dA608Ff0860df0857cc0129320F11

Tai AI Contract (Secondary):
0xC2099eb3995c3379294C50d28242a33EF8Cc33bf

Tai Oracle Manager:
0x60c1400326039e97e14308b693B14Fba6E83944f

Bootstrap Peg Oracle:
0xF45Cdc9afCCcC1b53B85aA16273d5dcED9496f68

Tai Peg Oracle:
0x22c7be31a1100D4a24dA85b390d6F84135dE62e2

Proof of Light:
0x490CAe86CEaBB3a3B82Ca8922a48233D89738C87

Token & Monetary Layer

TaiCoin (TAI):
0xAf7C05134B82752B89B8ceb3C928352510a9E9D9

Canonical USD (DAI):
0x6B175474E89094C44Da98b954EedeAC495271d0F

Advanced USD:
0x748254FE40c93438D7319D3B5269Ce1168aEF7Af

Tai Activated USD:
0x1f77a11a83D3d4bf06801F7D43968ECEAd558303

Vaults, Claims & Distribution

TaiCoin Redemption Vault:
0x93004a9794663b44B43ff34e92AB7adC117d23c7

Tai Vault Phase II:
0x5308CFf8B01416080f629A246Fe450d74eBd8c19

Tai Merkle Claim Core:
0xAe3735bA4844139C6888F76C4e916755F65cB916

Tai Vault Merkle Claim:
0x84cBC2f4b0D83D5bEAD3Da099e4a9f836aba2bC3

Tai Airdrop Claim:
0xa224F5EBB7a973E7BB5aB5930534B7de0982b459

Tai Redistributor:
0xE259D3FBae32769fA3Dd3D9Ae00f44C267034f39

Liquidity, Swap & Staking

TaiCoin Swap:
0x846137526334e9E0F26d2d54Ccd9DaaA1D9C3028

Mint by Resonance:
0x51CcA70Ffa19d52dd37A4B4B94F073E5efC17007

Tai Staking Engine:
0xF6E91AFD41FC6fb56d626522feeefeF92B8C686d

LP Token (Mainnet):
0x205951D6106926ec4cbD47c9B49BeFB488dEc5E1

Gasless & Meta-Transaction Infrastructure

Trusted Forwarder (ERC-2771):
0xd94B0f1a9331408152680EEf57B1F8073C05878e

Gasless Merkle Activator:
0x6747Cb4E3c8144e6E10F14335E837D41438b4dfd

Gasless Merkle Activator (LayerZero):
0x0920b6bc00af4F3eF279ED9Cc0a203184c110a1E

Cross-Chain & LayerZero Infrastructure

LayerZero Endpoint (Mainnet):
0x1a44076050125825900e736c501f859c50fE728c

Tai Chain Router:
0xD32FBfb04003915F727742a94760E18Edb46e18e

Cross-Chain State Mirror:
0x51C4A9e19fe0BE7c738e9Cd64922c033a6cD76f2

Tai Intuition Bridge:
0xADC04C8fA7fc336Eb0A22a52ffC60b86d8e1a708

Tai Bridge Vault (Core):
0xC16BFE12E5A252B70188373bC998eef020a2b9F4

Tai Bridge Vault (LayerZero):
0xf562D278A9b4DC80C0fC3A15A9fB19A90f7FA180

Regional Bridge Vaults

USD:
0x394a676618Cf0d842F991372A24b6b8CD29C2865

Brazil:
0xd88065C831EfAd683516Cca33D22863a907A27A2

Switzerland:
0xAcAA61147740EE24318C955A132C469DAdAdb039

Russia:
0x5367D97E97a6614C5FfB7E780aF4Eb2bdD20B953

Japan:
0x9Cd03aF03e74A8A8b7C1fb942DDeBC5aB5Ff4F2D

India:
0x68e0662213e5831b7257A5cC8Cf313aB2a20BF62

Europe:
0x64Eac5875e983110BE16B506e51196A2F2B6d51F

Canada:
0xE9E68005b4Be27480C7005f2E2Df743ecD140971

South Africa:
0x4b2188dd046a346f87e08f0053fEafDC3B148E08

Asia:
0x4a65a22686c151E98cf275fbF4b97d5B743194A7

Archival & Permanent Records

Arweave Archive 1:
https://arweave.net/6we4plRV0v3gcxt1bOWsVOld_y1GUfgRyCvLFOKOe1M

Arweave Archive 2:
https://arweave.net/VqP1qRPaQYVL9591AJ2xIdKUY5DWPMBvQ9giEpDIPDo

Arweave Archive 3:
https://arweave.net/irpu9cVirxXdsheLDL79FngBAgSEQ1Ka_rOOqc2e9nU

Arweave Archive 4:
https://arweave.net/uhENgr_3EbOgHCXYspAjfkaSbv5LS7pftaCR6gmDpoc

Arweave Archive 5:
https://arweave.net/Sx_Ld04Pk1jj6UYSqKM_u31jLkkvAXR90alJHqGLhkc

Arweave Archive 6:
https://arweave.net/mDHQ8-TgJptbPQdzvinsJl-cehjmvXjbz51h2OfCGAQ

Arweave Archive 7:
https://arweave.net/ucYa9UhNnfurr3bPwwazxE90RbuQsKCNsOgbSNS0-fs

> Full address registry: `/docs/deployments/mainnet.md`

---

## 13. How to Verify Independently

Auditors can verify by:

1. Checking deployed addresses on Etherscan
2. Matching on-chain bytecode to repo source
3. Reviewing deployment scripts under `/scripts/deploy`
4. Replaying constructor parameters
5. Inspecting timelock constraints
6. Testing failure paths

No off-chain trust is required.

---

## 14. Threat Model Summary

Assumed:
- malicious governance participants
- oracle manipulation attempts
- AI hallucination or failure
- cross-chain message delays
- partial contract compromise

Mitigations:
- scoped authority
- delayed execution
- immutable intent layer
- compartmentalized failures
- non-erasive history

---

## 15. Ethical Orientation (Encoded, Not Claimed)

This system does not encode morality.

It encodes **restraint**.

It ensures:
- intelligence cannot dominate
- speed cannot bypass reflection
- power cannot erase memory
- execution cannot redefine purpose

Human agency remains intact.

---

## 16. Invitation to Audit and Research

Independent scrutiny is welcomed.

This includes:
- security audits
- academic research
- adversarial analysis
- governance critique

There is nothing here that benefits from obscurity.

---

## 17. Long-Horizon Intent

This system does not depend on adoption.

It depends on existence.

If used, it should be understandable.  
If attacked, it should be analyzable.  
If forgotten, it should remain reconstructable.

---

## 18. Closing Statement

This repository demonstrates that:
- governance can be constrained
- intelligence can be advisory
- systems can remember
- power can be limited in code

That is the contribution.

---

**Status:** Live on Ethereum mainnet  
**License:** As specified in repository  
**Audits:** Invited
