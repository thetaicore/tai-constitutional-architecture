// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface ITaiVault {
    function notifyDeposit(address from, uint256 amount) external;
    function notifyWithdraw(address from, uint256 amount) external;
}

interface ITaiAI {
    function validateMint(address user, uint256 amount) external view returns (bool);
}

/**
 * @title TaiCoin
 * @notice Primary monetary primitive of the Tai protocol
 * @dev LOGIC CARRIER — MUST REMAIN ABSTRACT (SYSTEM LAW)
 */
abstract contract TaiCoin is ERC20, AccessControl {

    /*═════════════════════════════════
        ARWEAVE LINKS (Immutable)
    ═════════════════════════════════*/
    string public constant TAICOIN_WHITEPAPER = "https://www.arweave.net/6we4plRV0v3gcxt1bOWsVOld_y1GUfgRyCvLFOKOe1M";
    string public constant THE_RETURN_INTRO = "https://www.arweave.net/VqP1qRPaQYVL9591AJ2xIdKUY5DWPMBvQ9giEpDIPDo";
    string public constant ARCHITECTURE_OF_THE_RETURN = "https://www.arweave.net/irpu9cVirxXdsheLDL79FngBAgSEQ1Ka_rOOqc2e9nU";
    string public constant MAGNUM_OPUS = "https://www.arweave.net/uhENgr_3EbOgHCXYspAjfkaSbv5LS7pftaCR6gmDpoc";
    string public constant FROM_OUR_FAMILY_TO_YOURS = "https://www.arweave.net/iTsItpyK9gstlq4hvoDoU6Lvpc2NIczB_7PwPYGfvgk";
    
    /*═════════════════════════════════
        ROLES
    ═════════════════════════════════*/
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant DAO_ROLE    = keccak256("DAO_ROLE");

    /*═════════════════════════════════
        SUPPLY CONTROL
    ═════════════════════════════════*/
    uint256 public maxSupply; // 0 = uncapped

    /*═════════════════════════════════
        TRANSFER COOLDOWN
    ═════════════════════════════════*/
    uint256 public cooldown = 30;
    mapping(address => uint256) public lastTransfer;

    /*═════════════════════════════════
        MINT DYNAMICS
    ═════════════════════════════════*/
    uint256 public baseRate = 1000;
    uint256 public mintingRate;
    uint256 public adjustmentFactor = 10;
    uint256 public scale = 1000;

    /*═════════════════════════════════
        ENERGETIC MODULATION (BOUNDED)
    ═════════════════════════════════*/
    uint256 public frequencyModulation = 1;
    uint256 public lightVoidIntensity  = 1;

    uint256 public constant MAX_INTENSITY = 10;
    uint256 public constant MAX_FREQUENCY = 10;

    /*═════════════════════════════════
        EXTERNAL BINDINGS
    ═════════════════════════════════*/
    ITaiVault public taiVault;
    ITaiAI    public taiAI;

    /*═════════════════════════════════
        EVENTS
    ═════════════════════════════════*/
    event TaiVaultUpdated(address indexed newVault);
    event TaiAIUpdated(address indexed newAI);
    event EnergeticsUpdated(uint256 frequency, uint256 intensity);
    event CooldownUpdated(uint256 cooldown);
    event MintingRateUpdated(uint256 rate);
    event MaxSupplyUpdated(uint256 maxSupply);

    /*═════════════════════════════════
        CONSTRUCTOR (ABSTRACT BASE)
    ═════════════════════════════════*/
    constructor() ERC20("TaiCoin", "TAI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(DAO_ROLE, msg.sender);

        mintingRate = baseRate;
    }

    /*═════════════════════════════════
        CONFIGURATION
    ═════════════════════════════════*/
    function setTaiVault(address _vault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_vault != address(0), "Vault zero");
        taiVault = ITaiVault(_vault);
        emit TaiVaultUpdated(_vault);
    }

    function setTaiAI(address _ai) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_ai != address(0), "AI zero");
        taiAI = ITaiAI(_ai);
        emit TaiAIUpdated(_ai);
    }

    function setEnergetics(
        uint256 frequency,
        uint256 intensity
    ) external onlyRole(DAO_ROLE) {
        require(frequency <= MAX_FREQUENCY, "Frequency too high");
        require(intensity <= MAX_INTENSITY, "Intensity too high");

        frequencyModulation = frequency;
        lightVoidIntensity  = intensity;

        emit EnergeticsUpdated(frequency, intensity);
    }

    function setCooldown(uint256 seconds_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cooldown = seconds_;
        emit CooldownUpdated(seconds_);
    }

    function setMaxSupply(uint256 _max) external onlyRole(DAO_ROLE) {
        maxSupply = _max;
        emit MaxSupplyUpdated(_max);
    }

    function updateMintingRateByIntent(uint256 intentScore)
        external
        onlyRole(DAO_ROLE)
    {
        mintingRate = baseRate + (intentScore * adjustmentFactor) / scale;
        emit MintingRateUpdated(mintingRate);
    }

    /*═════════════════════════════════
        MINTING / BURNING
    ═════════════════════════════════*/
    function mint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        require(address(taiAI) != address(0), "AI not set");
        require(taiAI.validateMint(to, amount), "AI rejected mint");

        if (maxSupply != 0) {
            require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        }

        _mint(to, amount);

        if (address(taiVault) != address(0)) {
            try taiVault.notifyDeposit(to, amount) {} catch {}
        }
    }

    function burn(address from, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
    {
        _burn(from, amount);

        if (address(taiVault) != address(0)) {
            try taiVault.notifyWithdraw(from, amount) {} catch {}
        }
    }

    function exponentialMint(address to, uint256 baseAmount)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        require(address(taiAI) != address(0), "AI not set");
        require(taiAI.validateMint(to, baseAmount), "AI rejected mint");

        uint256 mintAmount = baseAmount;

        for (uint256 i = 0; i < lightVoidIntensity; i++) {
            mintAmount = (mintAmount * (scale + frequencyModulation)) / scale;
        }

        if (maxSupply != 0) {
            require(totalSupply() + mintAmount <= maxSupply, "Max supply exceeded");
        }

        _mint(to, mintAmount);

        if (address(taiVault) != address(0)) {
            try taiVault.notifyDeposit(to, mintAmount) {} catch {}
        }

        return mintAmount;
    }

    /*═════════════════════════════════
        TRANSFER GOVERNANCE
        (OpenZeppelin v5 normalization)
    ═════════════════════════════════*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (
            from != address(0) &&
            to != address(0) &&
            !hasRole(MINTER_ROLE, from) &&
            !hasRole(BURNER_ROLE, from)
        ) {
            require(
                block.timestamp >= lastTransfer[from] + cooldown,
                "Cooldown active"
            );
            lastTransfer[from] = block.timestamp;
        }
    }

}

/**
 * @title TaiCoinInstance
 * @notice Concrete deployable shell — NO LOGIC, NO STORAGE, NO OVERRIDES
 */
contract TaiCoinInstance is TaiCoin {
    constructor() TaiCoin() {}
}

