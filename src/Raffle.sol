// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Raffle {
  /* Errors */
  error Raffle__SendMoreToEnterRaffle();
  
  uint256 private immutable i_entranceFee;

  constructor(uint256 entranceFee) {
    i_entranceFee = entranceFee;
  }

  function enterRaffle() public payable {
    require(msg.value >= i_entranceFee, "Not enough ETH sent!");
    if(msg.value < i_entranceFee) {
      revert Raffle__SendMoreToEnterRaffle();
    }
  }

  function pickWinner() public {}
}
