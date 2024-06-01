// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "../interfaces/ItaskCallee.sol";
import "../interfaces/ITaskControlWithToken.sol";

contract CrossChainSenderTaskControl is
    ITaskControlWithToken,
    Ownable,
    ReentrancyGuard
{
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.

    IRouterClient private s_router;
    uint64 s_destinationChainSelector;
    address s_controlReceiverTask;
    LinkTokenInterface private s_linkToken;

    mapping(address => uint256) public taskMap; //Record tasks and weights

    event TaskAdd(address taskAddr, uint256 weight);
    event TokenToBeMint(
        address sender,
        address taskAddr,
        address receiveAddress,
        uint256 amount
    );
    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId,
        address receiver,
        uint256 fees
    );

    constructor(
        address _router,
        address _link,
        uint64 _destinationChainSelector,
        address _controlReceiverTask
    ) Ownable() {
        s_router = IRouterClient(_router);
        s_linkToken = LinkTokenInterface(_link);
        s_destinationChainSelector = _destinationChainSelector;
        s_controlReceiverTask = _controlReceiverTask;
    }

    function setDestination(
        uint64 _destinationChainSelector,
        address _controlReceiverTask
    ) external onlyOwner {
        s_destinationChainSelector = _destinationChainSelector;
        s_controlReceiverTask = _controlReceiverTask;
    }

    //Set the task and weight. If the weight is 0, it is equivalent to deleting the task.
    function setTask(address _taskAddr, uint256 _weight) external onlyOwner {
        taskMap[_taskAddr] = _weight;
        emit TaskAdd(_taskAddr, _weight);
    }
    function getTask(address _taskAddr) external view returns (uint256) {
        return taskMap[_taskAddr];
    }

    function mintToken(
        address _taskAddr,
        address _receiveAddress,
        bytes calldata _data
    ) external payable virtual override nonReentrant {
        require(taskMap[_taskAddr] != 0, "no set as task");

        //The actual number of minted tokens is the run task return value *weight
        uint256 value = ItaskCallee(_taskAddr).taskCall{value: msg.value}(
            address(msg.sender),
            _data
        );

        uint256 amount = value * taskMap[_taskAddr];

        sendTokenMintMessage(_taskAddr, _receiveAddress, amount);
        emit TokenToBeMint(
            address(msg.sender),
            _taskAddr,
            _receiveAddress,
            amount
        );
    }

    function sendTokenMintMessage(
        address _taskAddr,
        address _receiveAddress,
        uint256 _amount
    ) internal {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(s_controlReceiverTask), // ABI-encoded receiver address
            data: abi.encode(_taskAddr, _receiveAddress, _amount), // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            // Set the feeToken  address, indicating LINK will be used for fees
            feeToken: address(s_linkToken)
        });

        // Get the fee required to send the message
        uint256 fees = s_router.getFee(
            s_destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        s_linkToken.approve(address(s_router), fees);

        // Send the message through the router and store the returned message ID
        bytes32 messageId = s_router.ccipSend(
            s_destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(messageId, s_controlReceiverTask, fees);
    }

    //Spend your own task tokens and participate in the lottery
    function getTicket(
        uint256 _id,
        address _receiveAddress,
        uint256 _ticketNumbers
    ) external virtual override {
        //do nothing
    }
    //Spend third-party authorized task tokens and participate in the lottery
    function getTicketFrom(
        uint256 _id,
        address _fromAddress,
        address _receiveAddress,
        uint256 _ticketNumbers
    ) external virtual override {
        //do nothing
    }
    //Withdraw third-party tokens
    function withdraw(
        address _token,
        address _to,
        uint256 _value
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _value);
    }
}
