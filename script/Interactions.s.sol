// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscritption is Script {
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
  
  function run() public {}
}
