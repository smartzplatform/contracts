'use strict';

import expectThrow from '../helpers/expectThrow';


const Token = artifacts.require("TokenForSwap.sol");
const Swap = artifacts.require("SwapTokenForEther.sol");
const l = console.log;

const finney = x => web3.toWei(x, 'finney');
const balanceOf =  async addr => web3.eth.getBalance(addr);

contract('SwapTokenForEther', function(accounts) {

    const role =  {
        tokenOwner: accounts[0],
		participant1: accounts[1],
		participant2: accounts[2],
        nobody: accounts[9]
	};

    let instance, token;

    beforeEach(async function() {
        token = await Token.new({from: role.tokenOwner});
        await token.mint(role.participant1, 100, {from:role.tokenOwner});

        //participant 1 want to swap
        instance = await Swap.new(
            role.participant1,
            token.address,
            50,
            role.participant2,
            finney(20)
        );
    });

    it("complex test", async function() {


        assert.equal(0, await token.balanceOf(role.participant2));

        await expectThrow(instance.swap({from: role.nobody}));

        // only p2 can send ether
        await expectThrow(instance.sendTransaction({from: role.participant1, value: finney(19)}));

        // not full amount
        await token.transfer(instance.address, 49, {from: role.participant1});
        await expectThrow(instance.swap({from: role.nobody}));
        assert.equal(49, await instance.participant1SentTokensCount());

        // not full amount
        await instance.sendTransaction({from: role.participant2, value: finney(19)});
        await expectThrow(instance.swap({from: role.nobody}));
        assert.equal(finney(19), await instance.participant2SentEtherCount());

        // not full amount
        await token.transfer(instance.address, 1, {from: role.participant1});
        await expectThrow(instance.swap({from: role.nobody}));

        //success
        let part1InitialBalance = await balanceOf(role.participant1);
        await instance.sendTransaction({from: role.participant2, value: finney(1)});
        await instance.swap({from: role.nobody});

        assert.equal(50, await token.balanceOf(role.participant2));
        assert(part1InitialBalance.add(finney(20)) - await balanceOf(role.participant1) < 100000);

        //no second swap
        await expectThrow(instance.swap({from: role.participant1}));

        //no second sending of ether
        await expectThrow(instance.sendTransaction({from: role.participant2, value: finney(19)}));
    });

    it("swap more than expected", async function() {

        assert.equal(0, await token.balanceOf(role.participant2));
        assert.equal(100, await token.balanceOf(role.participant1));

        let part2InitialBalance = await balanceOf(role.participant2);
        await instance.sendTransaction({from: role.participant2, value: finney(21)});
        assert(part2InitialBalance.sub(finney(20)) - await balanceOf(role.participant2) < 100000);
        assert.equal(finney(20), await balanceOf(instance.address));


        await token.transfer(instance.address, 51, {from: role.participant1});

        let part1InitialBalance = await balanceOf(role.participant1);
        await instance.swap({from: role.participant1});

        assert.equal(50, await token.balanceOf(role.participant1));
        assert.equal(50, await token.balanceOf(role.participant2));
        assert(part1InitialBalance.add(finney(20)) - await balanceOf(role.participant1) < 100000);
    });

    it("refund", async function() {

        // p1
        assert.equal(100, await token.balanceOf(role.participant1));
        await token.transfer(instance.address, 51, {from: role.participant1});
        assert.equal(49, await token.balanceOf(role.participant1));
        await expectThrow(instance.refund({from: role.nobody}));
        await instance.refund({from: role.participant1});
        assert.equal(100, await token.balanceOf(role.participant1));

        // p2
        let part1InitialBalance = await balanceOf(role.participant1);
        await instance.sendTransaction({from: role.participant2, value: finney(21)});
        await expectThrow(instance.refund({from: role.nobody}));
        await instance.refund({from: role.participant2});
        assert(part1InitialBalance - await balanceOf(role.participant1) < 100000);
    });

    it("refund after swap", async function() {

        await token.transfer(instance.address, 51, {from: role.participant1});
        await instance.sendTransaction({from: role.participant2, value: finney(21)});
        await instance.swap({from: role.participant2});

        // p1
        assert.equal(50, await token.balanceOf(role.participant1));
        await token.transfer(instance.address, 45, {from: role.participant1});
        assert.equal(5, await token.balanceOf(role.participant1));
        await expectThrow(instance.refund({from: role.nobody}));
        await instance.refund({from: role.participant1});
        assert.equal(50, await token.balanceOf(role.participant1));

        // p2
        await expectThrow(instance.sendTransaction({from: role.participant2, value: finney(19)}));
    });

});
