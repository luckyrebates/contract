//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRandom.sol";

contract TestRandomGenerator is IRandomGenerator, Ownable {
    uint32 numWords = 1; //Amount of random numbers

    struct RequestStatus {
        uint256 id;
        bool fulfilled; //whether the request has been successfully fulfilled
        bool exists; //whether a requestId exists
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) private requestIdMap;
    mapping(address => bool) operatorAddressMap;

    event RandomWordsrRequest(uint256 indexed id, uint256 indexed requestId);
    event RandomWordsGenerate(
        uint256 indexed id,
        uint256 indexed requestId,
        uint256[] randomWords
    );

    modifier onlyOperator() {
        require(operatorAddressMap[msg.sender] == true, "Not operator");
        _;
    }

    constructor() Ownable() {}

    function setOperatorAddressList(
        address _address,
        bool _opt
    ) external onlyOwner {
        require(_address != address(0), "Cannot be zero address");
        operatorAddressMap[_address] = _opt;
    }

    function IsOperatorAddress(address _address) external view returns (bool) {
        return operatorAddressMap[_address];
    }

    function requestRandomWords(uint256 _id) external onlyOperator {
        requestIdMap[_id] = RequestStatus({
            id: _id,
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        emit RandomWordsrRequest(_id, _id);
    }

    function fulfillRandomWords(
        uint256 _id,
        uint256[] calldata _randomWords
    ) external onlyOwner {
        require(requestIdMap[_id].exists, "request not found");
        requestIdMap[_id].fulfilled = true;
        requestIdMap[_id].randomWords = _randomWords;

        emit RandomWordsGenerate(_id, _id, _randomWords);
    }

    function getRandomWords(
        uint256 _id
    ) external view returns (uint256[] memory randomWords) {
        require(requestIdMap[_id].exists, "request not found");
        require(requestIdMap[_id].fulfilled, "request not fulfilled");
        return requestIdMap[_id].randomWords;
    }
}
