import hre from "hardhat";
import {deployTaskControlWithToken} from "../TaskControlWithToken-deploy"
import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";

export type {
    StakeETHTask,
    } from "../../typechain-types";

  export async function deployStakeETHTask() {

    const StakeETHTask = await hre.ethers.getContractFactory("StakeETHTask");
    const stakeETHTask = await StakeETHTask.deploy();
    await stakeETHTask.waitForDeployment();


    //const address = await whileListTask.getAddress();
    //console.log('whileListTask address:',address);

    return  stakeETHTask;
}
export async function bindStakeETHTask(){
    const  stakeETHTask  = await loadFixture(deployStakeETHTask);
    const  taskControl  = await loadFixture(deployTaskControlWithToken);
    
    const stakeETHTaskAddress = await stakeETHTask.getAddress();
    const rs = await taskControl.setTask(stakeETHTaskAddress,1);
    await rs.wait();

    return {stakeETHTask,taskControl}
}

/*
bindTaskControl().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
    });
*/
