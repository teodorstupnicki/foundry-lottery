// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
  function createSubscriptionUsingConfig() public returns (uint256, address) {
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
    return createSubscription(vrfCoordinator);
  }

  function createSubscription(address vrfCoordinator) public returns (uint256, address) {
    console.log("Creating subscription on chainId: ", block.chainid);
    vm.startBroadcast();
    uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
    vm.stopBroadcast();
    console.log("Your subscription Id is: ", subId);
    console.log("Please update the subscriptionId in HelperConfig.s.sol");
    return (subId, vrfCoordinator);
  }
  
  function run() public {
    createSubscriptionUsingConfig();
  }
}

contract FundSubscription is Script, CodeConstants {
  uint256 public constant FUND_AMOUNT = 3 ether;

  function fundSubscriptionUsingConfig() public {
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
    uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
    address linkToken = helperConfig.getConfig().link;
    fundSubscription(vrfCoordinator, subscriptionId, linkToken);
  }

  function fundSubscription(address vrfCoordinatorV2_5, uint256 subId, address link) public {
    console.log("Funding subscription: ", subId);
    console.log("Using vrfCoordinator: ", vrfCoordinatorV2_5);
    console.log("On ChainID: ", block.chainid);

    if (block.chainid == LOCAL_CHAIN_ID) {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subId, FUND_AMOUNT);
        vm.stopBroadcast();
    } else {
        console.log(LinkToken(link).balanceOf(msg.sender));
        console.log(msg.sender);
        console.log(LinkToken(link).balanceOf(address(this)));
        console.log(address(this));
        vm.startBroadcast();
        LinkToken(link).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
        vm.stopBroadcast();
    }
  }

  function run() public {
  }
}