//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^54.0.0
pragma solidity ^0.8.19;

import "../interfaces/ItaskCallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//If taskControl registers this contract, you can pledge eth through this contract and receive task tokens.
contract StakeETHTask is ItaskCallee, ERC20{
    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor()
        ERC20("Wrapped Ether", "WETH")  
    {
    }
    function deposit() public payable {
        _deposit(msg.sender, msg.value);
    }
    function _deposit(address from,uint256 value) internal {
        _mint(from, value);
        emit Deposit(from, value);
    }

    function _withdraw(address to,uint256 amount) internal {
        _burn(to, amount);
        payable(to).transfer(amount);
        emit Withdraw(to, amount);
    }

    receive() external payable {
        deposit();
    }

    function withdraw() external{
        uint256 value = this.balanceOf(msg.sender);
        _withdraw(msg.sender,value);
    }
    
    function taskCall(address _from,bytes calldata _data) external virtual override payable returns(uint256){
        _deposit(_from, msg.value);
        return msg.value;
    }
}