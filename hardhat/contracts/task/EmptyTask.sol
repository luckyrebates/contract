//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.19;

import "../interfaces/ItaskCallee.sol";

//If taskControl registers the contract, anyone can receive the task token
contract EmptyTask is ItaskCallee{
    function taskCall(address _from,bytes calldata _data) external virtual override payable returns(uint256){
        (uint256 value) = abi.decode(_data,(uint256));
        return value;
    }
}