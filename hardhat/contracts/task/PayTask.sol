//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.19;

import "../interfaces/ItaskCallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//If taskControl registers the contract, any transfer behavior through the contract can receive the task token.
contract PayTask is ItaskCallee,Ownable{
    using SafeERC20 for IERC20;
    address public payToken;
    address public targetAddress;

    event TargetAddressSet(address targetAddress);
    constructor(address _payToken,address _targetAddress)
            Ownable()
    {
        payToken = _payToken;
        targetAddress = _targetAddress;
        emit TargetAddressSet(_targetAddress);
    }
    function setTargetAddress(address _targetAddress)external onlyOwner{
        targetAddress = _targetAddress;
        emit TargetAddressSet(_targetAddress);
    }

    
    function _pay(address _from,uint256 _value) internal {
        IERC20(payToken).safeTransferFrom(_from, targetAddress, _value);

    }

    function taskCall(address _from,bytes calldata _data) external  virtual override payable returns(uint256){
        (uint256 value) = abi.decode(_data,(uint256));
        _pay(_from,value);
        return value;
    }
}