// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ItaskCallee{
    //Perform specific collection tasks
    function taskCall(address from,bytes calldata data) external  payable returns(uint256);
}
