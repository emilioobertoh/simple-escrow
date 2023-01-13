//TESTS FOR OUR ESCROW CONTRACT
const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");

describe("Escrow", async function () {


    describe("Testing Access Controls", function () {

        it("Sets the correct ownership on deployment", async function () {

            //gets an array of all accounts
            const [owner, acc1] = await ethers.getSigners();

            const Escrow = await hre.ethers.getContractFactory("Escrow");
            const escrow = await Escrow.deploy();
    
            expect(await escrow.owner()).to.equal(owner.address);
    
        })

        describe("addAdmin function", function () {

            it("only owner can call the function", async function () {

                //gets an array of all accounts
                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();
        
                await expect(escrow.connect(acc1).addAdmin(acc2.address)).to.be.revertedWith("Unauthorized address");    

            })
        })
        
    })

})