// Import required libraries
import Web3 from 'web3';
import WBTCVaultABI from './WBTCVaultABI.json'; // ABI for the WBTCVault contract

// Initialize Web3
const web3 = new Web3(window.ethereum);

// Contract details
const vaultAddress = '<VAULT_CONTRACT_ADDRESS>'; // Replace with deployed contract address
const vaultContract = new web3.eth.Contract(WBTCVaultABI, vaultAddress);

// DOM Elements
const depositForm = document.getElementById('depositForm');
const depositAmountInput = document.getElementById('depositAmount');
const depositButton = document.getElementById('depositButton');

const fundGasForm = document.getElementById('fundGasForm');
const fundGasAmountInput = document.getElementById('fundGasAmount');
const fundGasButton = document.getElementById('fundGasButton');

const withdrawGasForm = document.getElementById('withdrawGasForm');
const withdrawGasAmountInput = document.getElementById('withdrawGasAmount');
const withdrawGasButton = document.getElementById('withdrawGasButton');

const queryForm = document.getElementById('queryForm');
const depositorAddressInput = document.getElementById('depositorAddress');
const balanceDisplay = document.getElementById('balanceDisplay');
const beneficiaryDisplay = document.getElementById('beneficiaryDisplay');
const queryButton = document.getElementById('queryButton');

// Functions
async function deposit() {
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        const depositor = accounts[0];
        const amount = web3.utils.toWei(depositAmountInput.value, 'ether');

        await vaultContract.methods.deposit(amount).send({
            from: depositor
        });

        alert('Deposit successful!');
    } catch (error) {
        console.error('Error during deposit:', error);
        alert('Deposit failed. Please try again.');
    }
}

async function fundGas() {
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        const funder = accounts[0];
        const amount = web3.utils.toWei(fundGasAmountInput.value, 'ether');

        await vaultContract.methods.fundGas(funder).send({
            from: funder, value: amount
        });

        alert('Gas funded successfully!');
    } catch (error) {
        console.error('Error during gas funding:', error);
        alert('Gas funding failed. Please try again.');
    }
}

async function withdrawGas() {
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        const withdrawer = accounts[0];
        const amount = web3.utils.toWei(withdrawGasAmountInput.value, 'ether');

        await vaultContract.methods.withdrawGas(amount).send({
            from: withdrawer
        });

        alert('Gas withdrawn successfully!');
    } catch (error) {
        console.error('Error during gas withdrawal:', error);
        alert('Gas withdrawal failed. Please try again.');
    }
}

async function queryDeposit() {
    try {
        const depositorAddress = depositorAddressInput.value;

        const balance = await vaultContract.methods.checkBalance(depositorAddress).call();
        const beneficiary = await vaultContract.methods.checkBeneficiary(depositorAddress).call();

        balanceDisplay.innerText = `Balance: ${web3.utils.fromWei(balance, 'ether')} WBTC`;
        beneficiaryDisplay.innerText = `Beneficiary: ${beneficiary}`;
    } catch (error) {
        console.error('Error during query:', error);
        alert('Query failed. Please try again.');
    }
}

// Event Listeners
depositButton.addEventListener('click', (e) => {
    e.preventDefault();
    deposit();
});

fundGasButton.addEventListener('click', (e) => {
    e.preventDefault();
    fundGas();
});

withdrawGasButton.addEventListener('click', (e) => {
    e.preventDefault();
    withdrawGas();
});

queryButton.addEventListener('click', (e) => {
    e.preventDefault();
    queryDeposit();
});

// MetaMask connection
if (typeof window.ethereum !== 'undefined') {
    console.log('MetaMask is installed!');
} else {
    alert('Please install MetaMask to interact with this application.');
}
