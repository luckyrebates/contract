import hre from "hardhat";

import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

import {deployEmptyTask} from "../task/EmptyTask-deploy"
export type {
    CrossChainReceiverTask,
} from "../../typechain-types";

import type {
    BigNumberish,
    AddressLike,
  } from "ethers";

let _router:AddressLike;    //Source chain router
let _link:AddressLike;      //Source chain link token address
let _destinationChainSelector: BigNumberish;    //Target chain selector
let _controlReceiverTask: AddressLike;  //The cross-chain task address of the target chain



export async function deployCrossChainSenderTaskControl() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const CrossChainSenderTaskControl = await hre.ethers.getContractFactory("CrossChainSenderTaskControl");
    const crossChainSenderTaskControl = await CrossChainSenderTaskControl.deploy(_router,_link,_destinationChainSelector,_controlReceiverTask);
    await crossChainSenderTaskControl.waitForDeployment();
    
    return crossChainSenderTaskControl;
}



//Bind cross-chain tasks
export async function bindEmptyTask() {

    const  emptyTask  = await loadFixture(deployEmptyTask);
    const  crossChainSenderTaskControl  = await loadFixture(deployCrossChainSenderTaskControl);
    
    const emptyTaskAddress = await emptyTask.getAddress();
    const rs = await crossChainSenderTaskControl.setTask(emptyTaskAddress,1);
    await rs.wait();
    
    return {emptyTask,crossChainSenderTaskControl};
}
