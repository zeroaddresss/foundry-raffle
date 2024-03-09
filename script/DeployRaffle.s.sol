// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "../src/Raffle.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "./Interactions.s.sol";

contract DeployRaffle is Script {
  function run() external returns(Raffle, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig();

    (
      uint64 subscriptionId,
      bytes32 gasLane,
      uint256 interval,
      uint256 entranceFee,
      uint32 callbackGasLimit,
      address vrfCoordinator,
      address link,
      uint256 deployerKey
    ) = helperConfig.activeNetworkConfig(); // deconstructing

    if (subscriptionId == 0) {
      CreateSubscription createSubscription = new CreateSubscription();
      (subscriptionId, vrfCoordinator) = createSubscription.createSubscription(vrfCoordinator, deployerKey);

      FundSubscription fundSubscription = new FundSubscription();
      fundSubscription.fundSubscription(
        vrfCoordinator,
        subscriptionId,
        link,
        deployerKey
      );
    }

    vm.startBroadcast(deployerKey);
    Raffle raffle = new Raffle(
      entranceFee,
      interval,
      subscriptionId,
      callbackGasLimit,
      vrfCoordinator,
      gasLane
    );
    vm.stopBroadcast();

    AddConsumer addConsumer = new AddConsumer();
    addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, deployerKey);
    return (raffle, helperConfig);
  }

}