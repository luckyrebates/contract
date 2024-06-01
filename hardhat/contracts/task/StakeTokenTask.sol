//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^54.0.0
pragma solidity ^0.8.19;

import "../interfaces/ItaskCallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//If taskControl registers the contract, the specified token will be pledged through the contract to receive the task token.
contract StakeTokenTask is ItaskCallee{
    using SafeERC20 for IERC20;

    address public payToken;

    mapping (address => uint256) stakeNumMap;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor(address _payToken)
    {
        payToken = _payToken;
    }

    function _deposit(address _from,uint256 _amount) internal{
        require(_amount != 0 ,"deposit no zero");
        IERC20(payToken).safeTransferFrom(_from, address(this), _amount);
        stakeNumMap[_from] +=  _amount;
        emit Deposit(_from,_amount);
    } 

    function deposit(uint256 _amount) external {
        _deposit(msg.sender,_amount);
    }


    function depositFrom(address _from,uint256 _amount)external{
        _deposit(_from,_amount);
    }


    function _withdraw(address _to,uint256 _value)internal {
        require(stakeNumMap[_to] >= _value);
        IERC20(payToken).safeTransfer(_to, _value);
        stakeNumMap[_to] -= _value;
        emit Withdraw(_to, _value);
    }

    function withdraw() external{
        require(stakeNumMap[msg.sender] != 0,"withdraw no zero");
        uint256 amount = stakeNumMap[msg.sender];
        _withdraw(msg.sender,amount);
    }
    
    function taskCall(address _from,bytes calldata _data) external virtual override  payable returns(uint256){
        (uint256 value) = abi.decode(_data,(uint256));
        _deposit(_from,value);
        return value;
    }
}