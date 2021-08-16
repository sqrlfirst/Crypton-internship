import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {ethers} from "hardhat";

async function main() {
    let ownerStaking : SignerWithAddress;
    let ownerTokenReward : SignerWithAddress;
    let ownerTokenStaking : SignerWithAddress;

    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contracts with the account: ${deployer.address}`);
    
    const balance = await deployer.getBalance();
    console.log(`Account balance: ${balance.toString()}`);
    
    const TokenStake = await ethers.getContractFactory('BullDogToken');
    const tokenStake = await TokenStake.deploy();
    console.log(`Staking token address: ${tokenStake.address}`);
    await tokenStake.deployed();
    [ownerTokenStaking] = await ethers.getSigners();

    const TokenReward = await ethers.getContractFactory('PuppyToken');
    const tokenReward = await TokenReward.deploy();
    console.log(`reward token address: ${tokenReward.address}`);
    await tokenReward.deployed();
    [ownerTokenReward] = await ethers.getSigners();

    const start = 1629082898;
    const rewardTotal = 10000;

    const Staking = await ethers.getContractFactory('Staking');
    const staking = await Staking.deploy(rewardTotal, start);
    console.log(`Staking address: ${staking.address}`);
    await staking.deployed();
    [ownerStaking] = await ethers.getSigners();
    console.log(`Staking owner: ${ownerStaking.address}`);

    await staking.connect(ownerStaking).initialize(tokenReward.address, tokenStake.address);    
    console.log(`initialize is done`);
}

main() 
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });