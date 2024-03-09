// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployRaffle } from "../../script/DeployRaffle.s.sol";
import { Raffle } from "../../src/Raffle.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { Test, console } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
  /* Events */
  event EnteredRaffle(address indexed player);

  Raffle raffle;
  HelperConfig helperConfig;

  uint256 entranceFee;
  uint256 interval;
  bytes32 gasLane;
  uint64 subscriptionId;
  uint32 callbackGasLimit;
  address vrfCoordinator;

  address public PLAYER = makeAddr("player");
  uint256 public constant STARTING_USER_BALANCE = 10 ether;

  function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
    (raffle, helperConfig) = deployer.run();
    (
      subscriptionId,
      gasLane,
      interval,
      entranceFee,
      callbackGasLimit,
      vrfCoordinator,
      ,
    ) = helperConfig.activeNetworkConfig();
    vm.deal(PLAYER, STARTING_USER_BALANCE);
  }

  //////////////////
  // enterRaffle //
  /////////////////

  function testRaffleInitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
  }

  function testRaffleRevertsOnLowEntranceFee() public {
    // Arrange
    vm.prank(PLAYER);
    // Act / Assert
    vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
    raffle.enterRaffle();
  }

  function testRaffleRecordsPlayerWhenTheyEnter() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    address playerRecorded = raffle.getPlayer(0);
    assert(playerRecorded == PLAYER);
  }

  function testEmitsEventOnEntry() public {
    vm.prank(PLAYER);
    vm.expectEmit(true, false, false, false, address(raffle)); // see expectEmit input parameters from Foundry docs: https://book.getfoundry.sh/cheatcodes/expect-emit
    emit EnteredRaffle(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
  }

  function testCantEnterWhenRaffleIsCalculating() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    vm.expectRevert(Raffle.Raffle__NotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
  }

  //////////////////
  // checkUpkeep  //
  //////////////////

  function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
    // Arrange
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    // Act
    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    // Assert
    assert(!upkeepNeeded);
  }

  function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    // Act
    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    // Assert
    assert(!upkeepNeeded);
  }

  function testChekUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
    // Arrange
    vm.warp(block.timestamp + interval - 1);
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();

    // Act
    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    // Assert
    assert(!upkeepNeeded);
  }

  function testCheckUpkeepReturnsTrueWhenParametersAreFine() public {
    // Arrange
    vm.warp(block.timestamp + interval + 1);
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();

    // Act
    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    // Assert
    assert(upkeepNeeded);
  }

  //////////////////
  // performUpkeep //
  //////////////////

  function testPerformUpkeepCanOnlyRunIfCheckUpkeepReturnsTrue() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    // Act / Assert
    raffle.performUpkeep("");
  }

  function testPerformUpkeepRevertsIfCheckUpkeepReturnsFalse() public {
    // Arrange
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    // Act / Assert
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    uint256 raffleState = 0; // 0 is open, 1 is calculating
    vm.expectRevert(abi.encodeWithSelector(
      Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState
      ));
    raffle.performUpkeep("");
  }

  modifier raffleEnteredAndTimePassed() {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    _;
  }

  function testPerformUpkeepUpdatesRaffleStateANDEmitsRequestId() public raffleEnteredAndTimePassed {
    // Act
    vm.recordLogs();
    raffle.performUpkeep(""); // emits requestId
    Vm.Log[] memory logs = vm.getRecordedLogs();
    bytes32 requestId = logs[1].topics[1]; // all logs are recorded as bytes32 in Foundry

    Raffle.RaffleState rState = raffle.getRaffleState();

    assert(uint256(requestId) > 0);
    assert(uint256(rState) == 1);
  }

  /////////////////////////
  // fulfillRandomWords //
  ////////////////////////

  modifier skipFork() {
    if (block.chainid != 31337) /* Anvil chainId */ {
      return;
    }
    _;
  }

  function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
  public raffleEnteredAndTimePassed skipFork {
    // Arrange
    vm.expectRevert("nonexistent request");
    // problem: we might want to verify that no requests exist
    // this implies checking every index
    // VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(0, address(raffle));
    // fuzzing comes in handy here
    VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
  }

  function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
  public raffleEnteredAndTimePassed skipFork {
    // Arrange
    uint256 additionalEntrants = 5;
    uint256 startingIndex = 1;
    for (uint256 i = startingIndex; i < startingIndex+additionalEntrants; i++) {
      address player = address(uint160(i));
      hoax(player, STARTING_USER_BALANCE); // vm.prank + vm.deal
      raffle.enterRaffle{value: entranceFee}();
    }
      uint256 prize = entranceFee * (additionalEntrants + 1);

      // Act
      // first, get the requestId from event logs
      vm.recordLogs();
      raffle.performUpkeep("");
      Vm.Log[] memory logs = vm.getRecordedLogs();
      bytes32 requestId = logs[1].topics[1];

      uint256 previousTimestamp = raffle.getLastTimestamp();

      // pretend to be Chainklink VRF to get a random number
      VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

      // Assert
      // assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
      assert(uint256(raffle.getRaffleState()) == 0);
      assert(raffle.getRecentWinner() != address(0));
      assert(raffle.getLengthOfPlayers() == 0);
      assert(previousTimestamp < raffle.getLastTimestamp());
      console.log("getRecentWinner(): ", raffle.getRecentWinner());
      console.log("getRecentWinner().balance: ", raffle.getRecentWinner().balance);
      console.log("STARTING_USER_BALANCE: ", STARTING_USER_BALANCE);
      console.log("prize: ", prize);
      console.log("entranceFee: ", entranceFee);
      assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);
  }
}