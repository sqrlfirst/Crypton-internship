import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {expect} from "chai";
import {ethers} from "hardhat";
import * as mocha from "mocha-steps";
import {utils, BigNumber, BigNumberish,Contract} from "ethers";

const ZERO_ADDR = '0x0000000000000000000000000000000000000000';
const stakeSum = 100;

describe("Staking Contract testing", () => {

    const millionTokens = 1000000;

    let stakeToken : Contract;
    let rewardToken : Contract;
    let staking : Contract;
    let stakeTokenOwner : SignerWithAddress;
    let rewardTokenOwner : SignerWithAddress;
    let stakingOwner : SignerWithAddress;
    let stakerAddr1 : SignerWithAddress;
    let stakerAddr2 : SignerWithAddress;

    let timeNow = Math.floor(Date.now() / 1000) + 100;
    let rewardTotal = 1000000;
    let delayStart = 1000;
    let startTime = timeNow + delayStart;

    before(async function() {
        const StakeToken = await ethers.getContractFactory('BullDogToken');
        const StakeTokenDeploy = await StakeToken.deploy();
        stakeToken = await StakeTokenDeploy.deployed();
        [stakeTokenOwner, stakerAddr1, stakerAddr2] = await ethers.getSigners();
        console.log('Stake token has been deployed');
        
        const RewardToken = await ethers.getContractFactory('PuppyToken');
        const rewardTokenDeploy = await RewardToken.deploy();
        rewardToken = await rewardTokenDeploy.deployed();
        [rewardTokenOwner] = await ethers.getSigners();
        console.log('Reward token has been deployed');
        
        await ethers.provider.send("evm_setNextBlockTimestamp", [timeNow]);

        const Staking = await ethers.getContractFactory('Staking');
        const StakingDeploy = await Staking.deploy(
            rewardTotal,        
            startTime       
        );
        staking = await StakingDeploy.deployed();
        [stakingOwner] = await ethers.getSigners();
        console.log('Staking has been deployed');
        await staking.connect(stakingOwner).initialize(
            rewardToken.address,
            stakeToken.address 
        );

        await stakeToken.connect(stakeTokenOwner).transfer(stakerAddr1.address, millionTokens);
        await stakeToken.connect(stakeTokenOwner).transfer(stakerAddr2.address, millionTokens);
        await rewardToken.connect(rewardTokenOwner).transfer(staking.address, millionTokens);
        console.log('tokens has been given to stakers and staking');

    });


    describe('initialize function testing', function () {

        mocha.step('revert if caller is not admin', async function() {
            await expect( staking.connect(stakerAddr1).initialize(
                    rewardToken.address,
                    stakeToken.address
                )
            ).to.be.revertedWith(
                "initialize:: caller is not an admin"
            );
        });

        mocha.step('revert if address of reward or stake token is 0',async function() {
            await expect(  staking.connect(stakingOwner).initialize(
                    ZERO_ADDR,      // check
                    stakeToken.address
                )
            ).to.be.revertedWith(
                "initialize:: tokens addresses are zeros"
            );
            
        });

        // mocha.step('Normal operation',async function() {
        //     expect( 
        //         )
        //     ).to.equal(true);
        // });
    });

    describe('stake fucntion test', function() {
        mocha.step( 'revert if time not come', async function() {
            // something with time
            let tooEarlyBird = startTime + 100;
            ethers.provider.send("evm_setNextBlockTimestamp", [tooEarlyBird]);
            expect(
                staking.connect(stakerAddr1).stake(
                    stakeSum
                )
            ).to.be.revertedWith(
                "stake:: staking time is not come"
            );
        });

        mocha.step('revert on transfer step', async function() {          // if not alloweded or not enough tokens ?? 
            let normalTime = startTime + 1000;
            ethers.provider.send("evm_setNextBlockTimestamp", [normalTime]);
            let moreThanStakerHave = millionTokens+stakeSum;
            expect( 
                staking.connect(stakerAddr1).stake(
                    moreThanStakerHave
                )
            ).to.be.revertedWith(
                "not sure now, fill after tests"
            );
        });


    });


    describe('unstake function testing', function () {
        mocha.step('revert if to much to unstake', async function() {

        });

        mocha.step('all is okay', async function() {

        });

    });

    describe('claim function testing', async function () {

    });

    describe('changePercent function testing', async function () {

    });

    describe('testing of viewing functions', async function () {
        /*
         *
         */
    });


    describe('testing of some complex scenarios', async function() {
        // testing that claimed sum is correct



    });






});