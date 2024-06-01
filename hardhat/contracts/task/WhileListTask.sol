//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import "../interfaces/ItaskCallee.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//If taskControl registers the contract, the addresses recorded in _whileListAddr can receive task tokens
contract WhileListTask is ItaskCallee, Ownable {
    mapping(address => bool) _whileListAddr;
    constructor(address[] memory _operatorAddressList) Ownable() {
        for (uint i = 0; i < _operatorAddressList.length; i++) {
            require(
                _operatorAddressList[i] != address(0),
                "Cannot be zero address"
            );
            _whileListAddr[_operatorAddressList[i]] = true;
        }
    }
    function setWhileListAddress(
        address _whileAddress,
        bool _opt
    ) external onlyOwner {
        require(_whileAddress != address(0), "Cannot be zero address");
        _whileListAddr[_whileAddress] = _opt;
    }

    function taskCall(
        address _from,
        bytes calldata _data
    ) external payable virtual override returns (uint256) {
        require(_whileListAddr[_from] == true, "no allow address");
        uint256 value = abi.decode(_data, (uint256));
        return value;
    }
}
