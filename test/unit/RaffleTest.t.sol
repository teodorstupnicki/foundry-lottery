// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

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
        (raffle, helperConfig) = deployer.deployContract();
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

    vm.expectRevert();

  }
}
