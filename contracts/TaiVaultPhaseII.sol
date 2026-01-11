// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./layerzero/ILayerZeroEndpoint.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface ITaiCoin is IERC20 {
    function mint(address to, uint256 amount) external;
    function exponentialMint(address to, uint256 baseAmount) external returns (uint256);
}

interface ITai {
    function validateResonanceScore(uint256 resonanceScore) external view returns (bool);
    function getResonanceFactor() external view returns (uint256);
}

/*───────────────────────────── CONTRACT ─────────────────────────────*/
contract TaiVaultPhaseII is ERC2771Context, Ownable, ReentrancyGuard {
    /*───────────────────────────── STATE ─────────────────────────────*/
    ITaiCoin public immutable taiCoin;
    ITai public tai;
    ILayerZeroEndpoint public layerZeroEndpoint;

    uint256 public resonanceHarmonics;
    uint256 public polarityHealingIndex;
    uint256 public fractalCoherence;
    uint256 public serviceImpactMetric;

    uint256 public baseRate = 1080 ether; // Sacred baseline mint unit
    address public gasRelayer;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event ResonanceMint(
        address indexed receiver,
        uint256 resonanceScore,
        uint256 amount,
        string sourceType,
        string ipfsHash,
        string divineSignature
    );

    event GasRelayerUpdated(address indexed newGasRelayer);
    event LayerZeroEndpointUpdated(address indexed newEndpoint);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        address forwarder,
        address taiCoinAddress,
        address _gasRelayer,
        address _layerZeroEndpoint,
        address _taiAddress
    )
        ERC2771Context(forwarder)
        Ownable() // ⚡ v5+ pattern: no arguments
    {
        require(taiCoinAddress != address(0), "Invalid TaiCoin address");
        require(_gasRelayer != address(0), "Invalid gas relayer address");
        require(_layerZeroEndpoint != address(0), "Invalid LayerZero endpoint");
        require(_taiAddress != address(0), "Invalid TAI address");

        // Set contract deployer as owner (v5+ Ownable pattern)
        transferOwnership(_msgSender());

        taiCoin = ITaiCoin(taiCoinAddress);
        tai = ITai(_taiAddress);
        gasRelayer = _gasRelayer;
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

    /*───────────────────────────── MODIFIERS ─────────────────────────────*/
    modifier onlyGasRelayer() {
        require(_msgSender() == gasRelayer, "Caller is not the gas relayer");
        _;
    }

    /*───────────────────────────── ADMIN FUNCTIONS ─────────────────────────────*/
    function updateMetaphysicalFactors(
        uint256 rh,
        uint256 phi,
        uint256 fc,
        uint256 sim
    ) external onlyOwner {
        resonanceHarmonics = rh;
        polarityHealingIndex = phi;
        fractalCoherence = fc;
        serviceImpactMetric = sim;
    }

    function setBaseRate(uint256 newRate) external onlyOwner {
        baseRate = newRate;
    }

    function setGasRelayer(address _gasRelayer) external onlyOwner {
        require(_gasRelayer != address(0), "Invalid gas relayer address");
        gasRelayer = _gasRelayer;
        emit GasRelayerUpdated(_gasRelayer);
    }

    function setLayerZeroEndpoint(address _endpoint) external onlyOwner {
        require(_endpoint != address(0), "Invalid LayerZero endpoint address");
        layerZeroEndpoint = ILayerZeroEndpoint(_endpoint);
        emit LayerZeroEndpointUpdated(_endpoint);
    }

    /*───────────────────────────── CORE LOGIC ─────────────────────────────*/
    function frequencyMintMultiplier(uint256 resonanceScore) public view returns (uint256) {
        uint256 metaSignal =
            resonanceHarmonics +
            polarityHealingIndex +
            fractalCoherence +
            serviceImpactMetric;

        return (resonanceScore * baseRate * metaSignal) / 1e6;
    }

    function mintByResonance(
        address to,
        uint256 resonanceScore,
        string memory sourceType,
        string memory ipfsHash,
        string memory divineSignature
    ) external nonReentrant {
        address sender = _msgSender();
        require(to != address(0), "Invalid address");
        require(resonanceScore > 0 && resonanceScore <= 10000, "Invalid resonance score");
        require(tai.validateResonanceScore(resonanceScore), "Invalid resonance score as per TAI");

        uint256 mintAmount = frequencyMintMultiplier(resonanceScore);

        // Gas relayer compensation
        if (sender != gasRelayer) {
            require(gasRelayer != address(0), "Gas relayer not set");
            Address.sendValue(payable(gasRelayer), tx.gasprice * gasleft());
        }

        taiCoin.mint(to, mintAmount);

        emit ResonanceMint(to, resonanceScore, mintAmount, sourceType, ipfsHash, divineSignature);
    }

    /*───────────────────────────── CROSS-CHAIN (LayerZero v1) ─────────────────────────────*/
    function sendViaLayerZero(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable {
        require(address(layerZeroEndpoint) != address(0), "LayerZero endpoint not set");

        layerZeroEndpoint.send{value: msg.value}(
            _dstChainId,
            _destination,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /*───────────────────────────── EMERGENCY CONTROLS ─────────────────────────────*/
    function emergencyWithdrawERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(token.transfer(to, amount), "Transfer failed");
    }

    function emergencyWithdrawETH(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
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
}

