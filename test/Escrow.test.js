//TESTS FOR OUR ESCROW CONTRACT
const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const { constants, expectRevert } = require('@openzeppelin/test-helpers');

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

    describe("Testing basic functionality", function () {

        describe("Deposit function tests", async function () {

            it("Cannot make a deposit to Zero address", async function () {

                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();

                await expect(escrow.deposit(constants.ZERO_ADDRESS))
                    .to.be.revertedWith("Cannot escrow funds to zero address");

            })

            it("Can be called by a user and a deposit can be made", async function () {

                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();

                await expect(escrow.connect(acc1).deposit(acc2.address, { value: 1000 }))
                    .to.changeEtherBalances([acc1.address, escrow.address], [-1000, 1000]);

            })

            it("Creates transaction in mapping, txid is incremented and status is properly set up", async function () {

                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();

                await escrow.connect(acc1).deposit(acc2.address, { value: 1000 });

                const tx = await escrow.transactions(1);

                expect(tx.sender).to.be.equal(acc1.address);

                expect(tx.receiver).to.be.equal(acc2.address);

                expect(tx.status).to.be.equal(0);

                expect(tx.amount).to.be.equal(1000);

                expect(await escrow.txid()).to.be.equal(2);

            })
        })

        describe("Confirm function tests", function () {

            it("Can only be confirmed by SENDER", async function () {

                const [owner, acc1, acc2] = await ethers.getSigners();

                const Escrow = await hre.ethers.getContractFactory("Escrow");
                const escrow = await Escrow.deploy();

                await escrow.connect(acc1).deposit(acc2.address, { value: 1000 });

                await expect(escrow.confirm(1)).to.be.revertedWith("Transactions can only be confirmed by the sender");

                await escrow.connect(acc1).confirm(1);

                await expect(escrow.connect(acc1).confirm(1)).to.be.revertedWith("Transaction needs to be pending so it can be confirmed");

                const status = await escrow.transactions(1);

                await expect(status.status).to.be.equal(1);

            })

            it("Can only be confirmed while on PENDING status", function() {})
            it("Transaction status is changed to CONFIRMED upon confirmation", function() {})

        })
    })

})