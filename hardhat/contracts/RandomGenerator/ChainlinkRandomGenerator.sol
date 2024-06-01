//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRandom.sol";

contract ChainlinkRandomGenerator is VRFConsumerBaseV2Plus, IRandomGenerator {
    //chainlink vrf
    IVRFCoordinatorV2Plus COORDINATOR;
    uint256 subscriptionId;
    //Betsa'a kihsh = 0
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 64; //Confirm the number of blocks
    uint32 numWords = 1; //Amount of random numbers

    struct RequestStatus {
        uint256 id;
        bool fulfilled; //whether the request has been successfully fulfilled
        bool exists; //whether a requestId exists
        uint256[] randomWords;
    }

    mapping(uint256 => uint256) private id2RequestIdMap;
    mapping(uint256 => RequestStatus) private requestIdMap;
    mapping(address => bool) operatorAddressMap;

    event RandomWordsrRequest(uint256 indexed id, uint256 indexed requestId);
    event RandomWordsGenerate(
        uint256 indexed id,
        uint256 indexed requestId,
        uint256[] randomWords
    );

    event OperatorAddress(address operatorAddress, bool opt);

    modifier onlyOperator() {
        require(operatorAddressMap[msg.sender] == true, "Not operator");
        _;
    }

    constructor(
        uint256 _subscriptionId,
        address _VRFCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_VRFCoordinator) {
        subscriptionId = _subscriptionId;
        COORDINATOR = IVRFCoordinatorV2Plus(_VRFCoordinator);
        keyHash = _keyHash;
        operatorAddressMap[msg.sender] = true;
        emit OperatorAddress(msg.sender, true);
    }

    function setOperatorAddress(
        address _address,
        bool _opt
    ) external onlyOwner {
        require(_address != address(0), "Cannot be zero address");
        operatorAddressMap[_address] = _opt;
        emit OperatorAddress(_address, _opt);
    }

    function IsOperatorAddress(address _address) external view returns (bool) {
        return operatorAddressMap[_address];
    }

    function setRequestConfirmations(
        uint16 _requestConfirmations
    ) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function requestRandomWords(uint256 _id) external onlyOperator {
        //Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        requestIdMap[requestId] = RequestStatus({
            id: _id,
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        id2RequestIdMap[_id] = requestId;
        emit RandomWordsrRequest(_id, requestId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal virtual override {
        require(requestIdMap[_requestId].exists, "request not found");
        requestIdMap[_requestId].fulfilled = true;
        requestIdMap[_requestId].randomWords = _randomWords;

        emit RandomWordsGenerate(
            requestIdMap[_requestId].id,
            _requestId,
            _randomWords
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 id, bool fulfilled, uint256[] memory randomWords)
    {
        require(requestIdMap[_requestId].exists, "request not found");
        RequestStatus memory request = requestIdMap[_requestId];
        return (request.id, request.fulfilled, request.randomWords);
    }

    function getRandomWords(
        uint256 _id
    ) external view returns (uint256[] memory randomWords) {
        require(id2RequestIdMap[_id] != 0, "id not found");
        uint256 requestId = id2RequestIdMap[_id];
        require(requestIdMap[requestId].exists, "request not found");
        require(requestIdMap[requestId].fulfilled, "request not fulfilled");
        return requestIdMap[requestId].randomWords;
    }
}
