// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        automationUpdateInterval = config.automationUpdateInterval;
        raffleEntranceFee = config.raffleEntranceFee;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;


        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

  function testRaffleInitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
  }

  function testRaffleRevertsWhenYouDontPayEnough() public {
    // arrange
    vm.prank(PLAYER);
    // act
    // assert
    vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
    raffle.enterRaffle();
  }

  function testRaffleRecordsPlayersWhenTheyEnter() public {
    //arrange
    vm.prank(PLAYER);
    // act
    raffle.enterRaffle{value: raffleEntranceFee}();
    // assert
    address playerRecord = raffle.getPlayer(0);
    assert(playerRecord == PLAYER);
  }

  function testEnteringRaffleEmitsEvent() public {
    vm.prank(PLAYER);
    vm.expectEmit(true, false, false, false, address(raffle));
    emit RaffleEntered(PLAYER);
    raffle.enterRaffle{value: raffleEntranceFee}();
  }

  function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: raffleEntranceFee}();
    vm.warp(block.timestamp + automationUpdateInterval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value: raffleEntranceFee}();
  }

  /*//////////////////////////////////////////////////////////////
                              CHECKUPKEEP
  //////////////////////////////////////////////////////////////*/
  
  function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
    // Arrange
    vm.warp(block.timestamp + automationUpdateInterval + 1);
    vm.roll(block.number + 1);

    // Act
    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    // Assert
    assert(!upkeepNeeded);
  }

  /*//////////////////////////////////////////////////////////////
                            PERFORMUPKEEP
  //////////////////////////////////////////////////////////////*/

  function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: raffleEntranceFee}();
    vm.warp(block.timestamp + automationUpdateInterval + 1);
    vm.roll(block.number + 1);

    raffle.performUpkeep("");
  }

  function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
    // Arrange
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.getRaffleState();
    // Act / Assert
    vm.expectRevert(
        abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
    );
    raffle.performUpkeep("");
  }

  function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: raffleEntranceFee}();
    vm.warp(block.timestamp + automationUpdateInterval + 1);
    vm.roll(block.number + 1);

    // Act
    vm.recordLogs();
    raffle.performUpkeep(""); // emits requestId
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    // Assert
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    // requestId = raffle.getLastRequestId();
    assert(uint256(requestId) > 0);
    assert(uint256(raffleState) == 1); // 0 = open, 1 = calculating
  }

  /*//////////////////////////////////////////////////////////////
                          FULLFILLRANDOMWORDS
  //////////////////////////////////////////////////////////////*/

  modifier raffleEntered() {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: raffleEntranceFee}();
    vm.warp(block.timestamp + automationUpdateInterval + 1);
    vm.roll(block.number + 1);
    _;
  }

  modifier skipFork() {
    if (block.chainid != 31337) {
        return;
    }
    _;
  }

  function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered skipFork {
    vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
    VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(randomRequestId, address(raffle));
  }

  function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered skipFork {
    uint256 additionalEntrants = 3;
    uint256 startingIndex = 1;
    address expectedWinner = address(1);

    for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
        address newPlayer = address(uint160(i));
        hoax(newPlayer, 1 ether);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }
    uint256 startingTimestamp = raffle.getLastTimeStamp();
    uint256 winnerStartingBalance = expectedWinner.balance;

    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];
    VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(uint256(requestId), address(raffle));

    // assert
    address recentWinner = raffle.getRecentWinner();
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    uint256 winnerBalance = recentWinner.balance;
    uint256 endingTimeStamp = raffle.getLastTimeStamp();
    uint256 prize = raffleEntranceFee * (additionalEntrants + 1);

    assert(recentWinner == expectedWinner);
    assert(uint256(raffleState) == 0);
    assert(winnerBalance == winnerStartingBalance + prize);
    assert(endingTimeStamp > startingTimestamp);
  }
}
