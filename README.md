# 🎟️ Provably Fair Raffle Smart Contract

![Solidity Version](https://img.shields.io/badge/Solidity-0.8.18-blue)
![Chainlink](https://img.shields.io/badge/Chainlink-Integrated-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A decentralized, provably fair raffle system built on Ethereum using Chainlink VRF for secure randomness and Chainlink Automation for reliable execution.

## 🌟 Features

- Truly random winner selection using [Chainlink VRF](https://docs.chain.link/vrf)
- Automated raffle execution with Chainlink Automation
- Configurable for multiple networks (Mainnet, Sepolia, Anvil)
- Comprehensive testing suite
- Easy deployment and interaction scripts

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- [Node.js](https://nodejs.org/en/download/)
- [Yarn](https://yarnpkg.com/getting-started/install)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/zeroaddresss/provably-fair-raffle.git
   cd provably-fair-raffle
   ```

2. Install dependencies:
   ```
   forge install
   yarn install
   ```

3. Set up environment variables:
   ```
   cp .env.example .env
   ```
   Edit `.env` and add your `PRIVATE_KEY` and other necessary variables.

### Deployment

1. To deploy on a local Anvil chain:
   ```
   forge script script/DeployRaffle.s.sol --broadcast --rpc-url http://localhost:8545
   ```

2. To deploy on Sepolia testnet:
   ```
   forge script script/DeployRaffle.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL
   ```

## 📖 Detailed Documentation

### Smart Contracts

- `Raffle.sol`: Main raffle contract
- `HelperConfig.s.sol`: Configuration helper for different networks
- `Interactions.s.sol`: Scripts for VRF subscription management

### Key Functions

- `enterRaffle()`: Allow users to enter the raffle
- `performUpkeep()`: Trigger the raffle drawing (Chainlink Automation)
- `fulfillRandomWords()`: Callback for Chainlink VRF to provide randomness

### Configuration

The `HelperConfig.s.sol` script provides configurations for:
- Mainnet Ethereum
- Sepolia Testnet
- Local Anvil chain

Adjust the parameters in this file to customize the raffle settings for each network.

## 🧪 Testing

Run the test suite:

```
forge test
```

For gas reports:

```
forge test --gas-report
```

## 🛠 Deployment and Interaction

1. Deploy the Raffle contract:
   ```
   forge script script/DeployRaffle.s.sol --broadcast --rpc-url $YOUR_RPC_URL
   ```

2. Interact with the deployed contract:
   ```
   cast send $RAFFLE_CONTRACT_ADDRESS "enterRaffle()" --value 0.1ether --rpc-url $YOUR_RPC_URL
   ```

## 🔗 External Dependencies

- Chainlink VRF: For verifiable randomness
- Chainlink Automation: For automated raffle execution

## 🙏 Acknowledgments

- [Cyfrin](https://www.cyfrin.io) for the amazing educational contents
- [Chainlink](https://chain.link/) for providing decentralized services
- [Foundry](https://book.getfoundry.sh/) for the amazing Ethereum development toolchain
