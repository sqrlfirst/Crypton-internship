import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {expect} from "chai";
import {ethers} from "hardhat";
import * as mocha from "mocha-steps";
import {utils, BigNumber, BigNumberish,Contract} from "ethers";

const ZERO_ADDR = '0x0000000000000000000000000000000000000000';
const trans_cash = 100;


describe("Staking Contract testing", () => {

    let stakeToken : Contract;
    let rewardToken : Contract;
    let staking : Contract;
    let stakeTokenOwner : SignerWithAddress;
    let rewardTokenOwner : SignerWithAddress;
    let stakingOwner : SignerWithAddress;
    let stakerAddr1 : SignerWithAddress;
    let stakerAddr2 : SignerWithAddress;

    before(async function() {
        const StakeToken = await ethers.getContractFactory('BullDogToken');
        const StakeTokenDeploy = await StakeToken.deploy();
        stakeToken = await StakeTokenDeploy.deployed();
        [stakeTokenOwner, stakerAddr1, stakerAddr2] = await ethers.getSigners();

        const RewardToken = await ethers.getContractFactory('PuppyToken');
        const rewardTokenDeploy = await RewardToken.deploy();
        rewardToken = await rewardTokenDeploy.deployed();
        [rewardTokenOwner] = await ethers.getSigners();
        
        let startTime = Math.floor(Date.now() / 1000) + 100;
        let rewardTotal = 1000000;
        await ethers.provider.send("evm_setNextBlockTimestamp", [startTime]);

        const Staking = await ethers.getContractFactory('Staking');
        const StakingDeploy = await Staking.deploy(
            rewardTotal,        
            startTime       
        );
        staking = await StakingDeploy.deployed();
        [stakingOwner] = await ethers.getSigners();
    });


    describe('initialize function testing', function () {

        mocha.step('revert if caller is not admin', function() {
            expect( staking.connect(stakerAddr1).initialize(
                    rewardToken.address,
                    stakeToken.address
                )
            ).to.be.revertedWith(
                "initialize:: caller is not an admin"
            );
        });

        mocha.step('revert if address of reward or stake token is 0', function() {
            expect( staking.connect(stakingOwner).initialize(
                    0,      // check
                    stakeToken.address
                )
            ).to.be.revertedWith(
                "initialize:: tokens addresses are zeros"
            );
            
        });

        mocha.step('Normal operation', function() {
            expect( staking.connect(stakerAddr1).initialize(
                    rewardToken.address,
                    stakeToken.address
                )
            ).to.equal(true);
        });
    });


    describe('unstake function testing', function () {

    });

    describe('claim function testing', function () {

    });

    describe('changePercent function testing', function () {

    });

    describe('testing of viewing functions', function () {
        /*
         *
         */


    });






});