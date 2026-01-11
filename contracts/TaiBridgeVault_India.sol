// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title TaiBridgeVault_India
 * @notice India-denominated cross-chain vault (LayerZero v2 + ERC2771)
 * @dev Architecturally identical to TaiBridgeVaultLZ
 */
contract TaiBridgeVault_India is
    OApp,
    ERC2771Context,
    ReentrancyGuard,
    Pausable
{
    /*───────────────────────────── STATE ─────────────────────────────*/
    address public governor;

    mapping(address => uint256) public balances;
    mapping(address => bool) public activated;
    mapping(uint32 => bytes32) public trustedPeers;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event Activated(address indexed user, uint256 amount, uint256 timestamp);
    event CrossChainSent(uint32 indexed dstEid, address indexed user, uint256 amount);
    event CrossChainReceived(uint32 indexed srcEid, address indexed user, uint256 amount);
    event GovernorUpdated(address indexed newGovernor);
    event TrustedPeerSet(uint32 indexed eid, bytes32 peer);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        address _endpoint,
        address _forwarder
    )
        ERC2771Context(_forwarder)
        OApp(_endpoint, msg.sender)
    {
        require(_endpoint != address(0), "Invalid endpoint");
        require(_forwarder != address(0), "Invalid forwarder");
        governor = msg.sender;
    }

    /*───────────────────────────── ERC2771 OVERRIDES ─────────────────────────────*/
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength()
        internal
        view
        override(Context, ERC2771Context)
        returns (uint256)
    {
        return ERC2771Context._contextSuffixLength();
    }

    /*───────────────────────────── GOVERNANCE ─────────────────────────────*/
    modifier onlyGovernor() {
        require(_msgSender() == governor, "Not governor");
        _;
    }

    function setGovernor(address newGovernor) external onlyGovernor {
        require(newGovernor != address(0), "Governor cannot be zero");
        governor = newGovernor;
        emit GovernorUpdated(newGovernor);
    }

    function setTrustedPeer(uint32 eid, bytes32 peer) external onlyGovernor {
        trustedPeers[eid] = peer;
        emit TrustedPeerSet(eid, peer);
    }

    /*───────────────────────────── CROSS-CHAIN SEND ─────────────────────────────*/
    function sendCrossChain(
        uint32 dstEid,
        address user,
        uint256 amount
    )
        external
        payable
        onlyGovernor
        nonReentrant
        whenNotPaused
    {
        require(user != address(0), "Invalid user");
        require(amount > 0, "Amount must be > 0");

        bytes memory payload = abi.encode(user, amount);

        MessagingFee memory fee = MessagingFee({
            nativeFee: msg.value,
            lzTokenFee: 0
        });

        _lzSend(
            dstEid,
            payload,
            bytes(""),
            fee,
            payable(_msgSender())
        );

        emit CrossChainSent(dstEid, user, amount);
    }

    /*───────────────────────────── CROSS-CHAIN RECEIVE ─────────────────────────────*/
    function _lzReceive(
        Origin calldata origin,
        bytes32,
        bytes calldata payload,
        address,
        bytes calldata
    )
        internal
        override
        whenNotPaused
    {
        require(trustedPeers[origin.srcEid] == origin.sender, "Untrusted peer");

        (address user, uint256 amount) = abi.decode(payload, (address, uint256));

        activated[user] = true;
        balances[user] += amount;

        emit Activated(user, amount, block.timestamp);
        emit CrossChainReceived(origin.srcEid, user, amount);
    }

    /*───────────────────────────── EMERGENCY ─────────────────────────────*/
    function pause() external onlyGovernor {
        _pause();
    }

    function unpause() external onlyGovernor {
        _unpause();
    }
}

