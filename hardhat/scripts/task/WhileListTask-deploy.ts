import hre from "hardhat";
import {deployTaskControlWithToken} from "../TaskControlWithToken-deploy"
import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";


  export async function deployWhileListTask() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const WhileListTask = await hre.ethers.getContractFactory("WhileListTask");
    const whileListTask = await WhileListTask.deploy([owner]);
    await whileListTask.waitForDeployment();


    //const address = await whileListTask.getAddress();
    //console.log('whileListTask address:',address);

    return  whileListTask;
}
export async function bindWhileListTask(){
    const  whileListTask  = await loadFixture(deployWhileListTask);
    const  taskControl  = await loadFixture(deployTaskControlWithToken);
    
    const whileListTaskAddress = await whileListTask.getAddress();
    const rs = await taskControl.setTask(whileListTaskAddress,1);
    await rs.wait();
    //const tx = await rs.getTransaction();
    //console.log('bindTaskControl tx:',tx?.hash);
    return {whileListTask,taskControl}
}

/*
bindTaskControl().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
    });
*/
