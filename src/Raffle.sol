// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Raffle {
  /* Errors */
  error Raffle__SendMoreToEnterRaffle();
  
  uint256 private immutable i_entranceFee;
  address payable[] private s_players;

  /* Events */
  event RaffleEntered(address indexed player);

  constructor(uint256 entranceFee) {
    i_entranceFee = entranceFee;
  }

  function enterRaffle() public payable {
    if(msg.value < i_entranceFee) {
      revert Raffle__SendMoreToEnterRaffle();
    }
    s_players.push(payable(msg.sender));
    emit RaffleEntered(msg.sender);
  }

  function pickWinner() public {}
}
