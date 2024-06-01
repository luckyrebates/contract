// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IRandomGenerator{
    //Request a specific random number
    function requestRandomWords(uint256 id)external;

    //Query random number
    function getRandomWords(uint256 _id)external view returns(uint256[] memory randomWords);
}

