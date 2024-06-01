import hre from "hardhat";
import {deployTaskControlWithToken} from "../TaskControlWithToken-deploy"
import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";

export type {
    EmptyTask,
    } from "../../typechain-types";

  export async function deployEmptyTask() {

    const EmptyTask = await hre.ethers.getContractFactory("EmptyTask");
    const emptyTask = await EmptyTask.deploy();
    await emptyTask.waitForDeployment();


    //const address = await whileListTask.getAddress();
//console.log('whileListTask address:',address);

    return  emptyTask;
}
export async function bindEmptyTask(){
    const  emptyTask  = await loadFixture(deployEmptyTask);
    const  taskControl  = await loadFixture(deployTaskControlWithToken);
    
    const emptyTaskAddress = await emptyTask.getAddress();
    const rs = await taskControl.setTask(emptyTaskAddress,1);
    await rs.wait();

    return {emptyTask,taskControl}
}

/*
bindTaskControl().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
    });
*/
