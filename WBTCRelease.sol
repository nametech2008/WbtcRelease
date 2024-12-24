// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract WBTCVault {
    IERC20 public immutable wbtc;
    address public immutable owner;

    // Store user deposits and their beneficiaries
    struct DepositInfo {
        uint256 balance;
        address beneficiary;
        uint256 lastRelease;
    }

    mapping(address => DepositInfo) public deposits;

    // Store user gas balance
    mapping(address => uint256) public gasBalance;

    // Store pending releases (Gas deficiency case)
    mapping(address => bool) public pendingReleases;

    event Deposited(address indexed depositor, address indexed beneficiary, uint256 amount);
    event Released(address indexed beneficiary, uint256 amount);
    event GasFunded(address indexed funder, uint256 amount);
    event GasWithdrawn(address indexed withdrawer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _wbtc) {
        require(_wbtc != address(0), "Invalid WBTC address");
        wbtc = IERC20(_wbtc);
        owner = msg.sender;
    }

    // Deposit WBTC into the vault
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        DepositInfo storage info = deposits[msg.sender];

        if (info.beneficiary == address(0)) {
            info.beneficiary = msg.sender;
            info.lastRelease = block.timestamp;
        }

        require(info.beneficiary == msg.sender, "Beneficiary cannot be changed");

        wbtc.transferFrom(msg.sender, address(this), amount);
        info.balance += amount;

        emit Deposited(msg.sender, info.beneficiary, amount);
    }

    // Release 1% of the balance to the beneficiary once a year
    function release(address depositor) public {
        DepositInfo storage info = deposits[depositor];
        require(info.beneficiary != address(0), "No deposit exists for this address");

        uint256 currentYear = block.timestamp / 365 days;
        uint256 lastReleaseYear = info.lastRelease / 365 days;
        require(currentYear > lastReleaseYear || pendingReleases[depositor], "Release can only be done once per year");

        uint256 amount = info.balance / 100;
        require(amount > 0, "Insufficient balance to release");

        info.lastRelease = block.timestamp;
        info.balance -= amount;
        require(wbtc.transfer(info.beneficiary, amount), "WBTC transfer failed");

        pendingReleases[depositor] = false;
        emit Released(info.beneficiary, amount);
    }

    // Fund the contract with gas for a specific user
    function fundGas(address depositor) external payable {
        require(msg.value > 0, "Gas funding required");
        gasBalance[depositor] += msg.value;
        emit GasFunded(depositor, msg.value);
    }

    // Allow users to withdraw their gas balance if needed
    function withdrawGas(uint256 amount) external {
        require(gasBalance[msg.sender] >= amount, "Insufficient gas balance");
        gasBalance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit GasWithdrawn(msg.sender, amount);
    }

    // Allow direct transfer of WBTC to the contract
    receive() external payable {
        emit GasFunded(msg.sender, msg.value);
    }

    // Allow WBTC transfer to the contract
    function onERC20Received(address, uint256 amount, bytes calldata) external returns (bytes4) {
        require(msg.sender == address(wbtc), "Only WBTC can be transferred");
        DepositInfo storage info = deposits[msg.sender];

        if (info.beneficiary == address(0)) {
            info.beneficiary = msg.sender;
            info.lastRelease = block.timestamp;
        }

        info.balance += amount;
        emit Deposited(msg.sender, info.beneficiary, amount);

        return this.onERC20Received.selector;
    }

    // Check balance for a specific depositor
    function checkBalance(address depositor) external view returns (uint256) {
        return deposits[depositor].balance;
    }

    // Check beneficiary for a specific depositor
    function checkBeneficiary(address depositor) external view returns (address) {
        return deposits[depositor].beneficiary;
    }
}
