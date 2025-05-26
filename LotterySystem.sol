//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Lottery {
    address public manager;
    address[] public players;
    
    
    event PlayerEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner, uint256 amount);
    event LotteryReset();

    constructor() payable {
        manager = msg.sender; // Contract creator is the manager
    }

    // Players have to enter by giving min 0.01 ETH 
    function enterGame() public payable {
        require(msg.value >= 0.01 ether, "Minimum 0.01 ETH is required to enter");
        players.push(msg.sender);
        emit PlayerEntered(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getPlayersCount() public view returns (uint256) {
        return players.length;
    }

    function getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.prevrandao, 
            block.timestamp, 
            players.length,
            address(this).balance
        ))); 
    }

    function pickWinner() public {
        require(msg.sender == manager, "Only manager can pick winner");
        require(players.length >= 1, "There should be at least one player");
        
        uint256 randomNumber = getRandomNumber() % players.length;
        address winner = players[randomNumber];
        uint256 prizeAmount = address(this).balance;
        
       
        players = new address[](0);
        
        
        (bool success, ) = payable(winner).call{value: prizeAmount}("");
        require(success, "Transfer failed");
        
        emit WinnerPicked(winner, prizeAmount);
        emit LotteryReset();
    }

  
    function resetLottery() public {
        require(msg.sender == manager, "Only manager can reset lottery");
        players = new address[](0);
        emit LotteryReset();
    }

  
    function emergencyWithdraw() public {
        require(msg.sender == manager, "Only manager can withdraw");
        require(players.length == 0, "Cannot withdraw while players are in the game");
        
        uint256 balance = address(this).balance;
        (bool success, ) = payable(manager).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Prevent accidental ETH sends
    receive() external payable {
        revert("Use enterGame() to participate");
    }

    fallback() external payable {
        revert("Use enterGame() to participate");
    }
}