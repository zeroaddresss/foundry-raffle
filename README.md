
## About

This project implements a smart contract that allows users to participate in a raffle for a chance to win money. The project integrates Chainlink services, for two main purposes:

1. **Randomness:** Achieving randomness on-chain is challenging because EVM computation is deterministic. Therefore, we rely on [Chainlink's Verifiable Random Function (VRF)](https://docs.chain.link/vrf) service to randomly select the winner of the raffle.

2. **Automation:** The opening and drawing of each raffle are handled automatically by Chainlink's VRF [Coordinator](https://docs.chain.link/vrf/v2/subscription), eliminating the need for human interaction for each raffle.

In addition to implementing the raffle mechanism smart contract, [Foundry](https://book.getfoundry.sh/) is used for deployment scripts and to run tests on the code's behavior. While the tests performed do not guarantee 100% coverage, they are useful for practicing test writing with Foundry. This project serves as a valuable resource for practicing writing Solidity smart contracts that integrate third-party services (i.e., Chainlink) and formulating deployment scripts and tests in Foundry.
