// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Raffle {
  /* Errors */
  error Raffle__SendMoreToEnterRaffle();
  
  uint256 private immutable i_entranceFee;
  uint256 private immutable i_interval;
  address payable[] private s_players;
  uint256 private s_lastTimeStamp;

  /* Events */
  event RaffleEntered(address indexed player);

  constructor(uint256 entranceFee, uint256 interval) {
    i_entranceFee = entranceFee;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;
  }

  function enterRaffle() public payable {
    if(msg.value < i_entranceFee) {
      revert Raffle__SendMoreToEnterRaffle();
    }
    s_players.push(payable(msg.sender));
    emit RaffleEntered(msg.sender);
  }

  function pickWinner() public {
    if (block.timestamp - s_lastTimeStamp > i_interval) {
      revert();
    }
  }
}
