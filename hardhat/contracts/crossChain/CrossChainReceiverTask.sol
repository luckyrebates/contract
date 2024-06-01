//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "../interfaces/ItaskCallee.sol";
import "../interfaces/ITaskControlWithToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainReceiverTask is CCIPReceiver, ItaskCallee, Ownable {
    error NotSupportCrossChainSender(
        uint64 sourceChainSelector,
        address crossChainSenderAddr
    );

    ITaskControlWithToken taskControlWithToken;

    mapping(uint64 => mapping(address => bool)) public crossChainSenderMap; //Set the cross chain sender contract whitelist of the source chain

    event CrossChainTokenMint(
        bytes32 indexed messageId,
        address taskAddr,
        address receiveAddress,
        uint256 amount
    );
    event MessageReceive(
        bytes32 indexed messageId,
        uint64 sourceChainSelector,
        address sender
    );
    event CrossChainSet(
        uint64 indexed sourceChainSelector,
        address indexed crossChainSenderAddr,
        bool opt
    );

    modifier onlyTaskControl() {
        require(
            msg.sender == address(taskControlWithToken),
            "Not task control"
        );
        _;
    }

    constructor(
        address _router,
        address _taskControlWithToken
    ) CCIPReceiver(_router) Ownable() {
        taskControlWithToken = ITaskControlWithToken(_taskControlWithToken);
    }

    function setCrossChainSender(
        uint64 _sourceChainSelector,
        address _crossChainSenderAddr,
        bool _opt
    ) external onlyOwner {
        crossChainSenderMap[_sourceChainSelector][_crossChainSenderAddr] = _opt;
        emit CrossChainSet(_sourceChainSelector, _crossChainSenderAddr, _opt);
    }
    function getCrossChainSender(
        uint64 _sourceChainSelector,
        address _crossChainSenderAddr
    ) external view returns (bool) {
        return crossChainSenderMap[_sourceChainSelector][_crossChainSenderAddr];
    }
    function updateTaskControl(
        address _taskControlWithToken
    ) external onlyOwner {
        taskControlWithToken = ITaskControlWithToken(_taskControlWithToken);
    }

    //handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        bytes32 receivedMessageId = any2EvmMessage.messageId; //fetch the messageId

        (address taskAddr, address receiveAddress, uint256 amount) = abi.decode(
            any2EvmMessage.data,
            (address, address, uint256)
        ); //abi-decoding of the sent text

        emit MessageReceive(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, //fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)) //abi-decoding of the sender address,
        );

        address crossChainSenderAddr = abi.decode(
            any2EvmMessage.sender,
            (address)
        );
        emit MessageReceive(
            receivedMessageId,
            any2EvmMessage.sourceChainSelector,
            crossChainSenderAddr
        );

        if (
            crossChainSenderMap[any2EvmMessage.sourceChainSelector][
                crossChainSenderAddr
            ] != true
        )
            revert NotSupportCrossChainSender(
                any2EvmMessage.sourceChainSelector,
                crossChainSenderAddr
            );

        taskControlWithToken.mintToken(
            address(this),
            receiveAddress,
            abi.encode(amount)
        );
        emit CrossChainTokenMint(
            receivedMessageId,
            taskAddr,
            receiveAddress,
            amount
        );
    }

    function taskCall(
        address _from,
        bytes calldata _data
    ) external payable virtual override onlyTaskControl returns (uint256) {
        uint256 amount = abi.decode(_data, (uint256));
        return amount;
    }
}
