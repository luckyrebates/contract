import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import hre from "hardhat";

import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {StakeETHTask,deployStakeETHTask } from "../../scripts/task/StakeETHTask-deploy";
import { expect } from "chai";


describe("StakeETHTask", function (){
    let stakeETHTask:StakeETHTask;
    let owner:HardhatEthersSigner;
    before(async function(){
        stakeETHTask = await deployStakeETHTask();
        console.log('stakeETHTask address:',await stakeETHTask.getAddress());
        [owner] = await hre.ethers.getSigners();
    });
    it("deposit", async function () {
        const balance1 = await hre.ethers.provider.getBalance(owner);
        console.log('Account before balance:',balance1 );

        const overrides = {
            value: hre.ethers.parseEther("0.1"), // convert to wei
        };

        const deposit = stakeETHTask.deposit(overrides);
        await expect(deposit).not.to.be.reverted;
        const receipt = await (await deposit).wait();
        
        const balance2 = await hre.ethers.provider.getBalance(owner);
        console.log('Account after balance:',balance2 );

    });
    it("withdraw", async function () {

        const withdraw = stakeETHTask.withdraw();
        await expect(withdraw).not.to.be.reverted;
        const receipt = await (await withdraw).wait();
        
        const balance2 = await hre.ethers.provider.getBalance(owner);
        console.log('Account  balance:',balance2 );

    });

});