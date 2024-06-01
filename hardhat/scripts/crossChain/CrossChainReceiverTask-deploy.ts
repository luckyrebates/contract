import hre from "hardhat";

import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

export type {
    CrossChainReceiverTask,
    CrossChainSenderTaskControl,
} from "../../typechain-types";


import {TaskControlWithToken,deployTaskControlWithToken} from "../TaskControlWithToken-deploy"

import type {
    BigNumberish,
    AddressLike,
  } from "ethers";

let _router:AddressLike;    //Target chain router
let _sourceChainSelector: BigNumberish; //Source chain selector
let _crossChainSenderTaskControl:AddressLike;   //  Cross-chain task control address of the source chain

export async function deployCrossChainReceiverTask() {
    const  taskControl  = await loadFixture(deployTaskControlWithToken);

    const CrossChainReceiverTask = await hre.ethers.getContractFactory("CrossChainReceiverTask");
    const crossChainSenderTaskControl = await CrossChainReceiverTask.deploy(_router,await taskControl.getAddress());
    await crossChainSenderTaskControl.waitForDeployment();
    
    return crossChainSenderTaskControl;
}


export async function bindTaskControlWithToken(){
    const taskControl  = await loadFixture(deployTaskControlWithToken);
    const crossChainSenderTaskControl = await loadFixture(deployCrossChainReceiverTask);


    const rs = await taskControl.setTask(await crossChainSenderTaskControl.getAddress(),1);
    await rs.wait();

    return {crossChainSenderTaskControl,taskControl}
}


//Bind cross-chain tasks
export async function setCrossChainSender() {
    const crossChainSenderTaskControl = await loadFixture(deployCrossChainReceiverTask);
    
    const rs = await crossChainSenderTaskControl.setCrossChainSender(_sourceChainSelector,_crossChainSenderTaskControl,true);
    await rs.wait();
    
    return crossChainSenderTaskControl;
}
