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

        describe("addAdmin and deleteAdmin functions", function () {

            it("only owner can call the addAdmin function", async function () {

                //gets an array of all accounts
                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();
        
                await expect(escrow.connect(acc1).addAdmin(acc2.address)).to.be.revertedWith("Unauthorized address");    

            })

            it("only owner can call the deleteAdmin function", async function () {

                //gets an array of all accounts
                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();
        
                await expect(escrow.connect(acc1).deleteAdmin(acc2.address)).to.be.revertedWith("Unauthorized address");    

            })

            it("a new admin can be listed/deleted and cannot list/delete an existing/non existing admin", async function () {

                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();
        
                await escrow.addAdmin(acc2.address);
                
                expect(await escrow.admins(acc2.address)).to.equal(true);

                await expect(escrow.addAdmin(acc2.address)).to.be.revertedWith("Admin already exist"); 
                
                await escrow.deleteAdmin(acc2.address);

                expect(await escrow.admins(acc2.address)).to.equal(false);

                await expect(escrow.deleteAdmin(acc2.address)).to.be.revertedWith("Can delete only listed admins"); 

            })

        })

        describe("Pause/Unpause functionality", function () {

            it("Only owner is able to pause the contract", async function () {

                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();

                expect(await escrow.paused()).to.be.equal(false);
    
                await expect(escrow.connect(acc1).pause()).to.be.revertedWith("Unauthorized address");

                await escrow.pause();

                expect(await escrow.paused()).to.be.equal(true);
    
            })

            it("Functions cannot be called while contract is paused", async function () {

                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();

                await escrow.pause();

                await expect(escrow.deposit(acc2.address)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.confirm(1)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.connect(acc2).withdraw(1)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.dispute(1)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.refund(1)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.release(1)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.addAdmin(acc2.address)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.deleteAdmin(acc2.address)).to.be.revertedWith("Pausable: paused");

                await expect(escrow.pause()).to.be.revertedWith("Pausable: paused");

            })


        })
        
    })

})