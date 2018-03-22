'use strict';

import expectThrow from '../helpers/expectThrow';


const Token = artifacts.require("TokenForSwap.sol");
const Swap = artifacts.require("SwapTokenForToken.sol");
const l = console.log;

contract('SwapTokenForToken', function(accounts) {

    const role =  {
        tokenOwner: accounts[0],
		participant1: accounts[1],
		participant2: accounts[2],
        nobody: accounts[9]
	};

    let instance, token1, token2;

    beforeEach(async function() {
        token1 = await Token.new({from: role.tokenOwner});
        await token1.mint(role.participant1, 100, {from:role.tokenOwner});

        token2 = await Token.new({from: role.tokenOwner});
        await token2.mint(role.participant2, 100, {from:role.tokenOwner});

        //participant 1 want to swap
        instance = await Swap.new(
            role.participant1,
            token1.address,
            50,
            role.participant2,
            token2.address,
            20,
        );
    });

    it("complex test", async function() {

        assert.equal(0, await token1.balanceOf(role.participant2));
        assert.equal(0, await token2.balanceOf(role.participant1));

        await expectThrow(instance.swap({from: role.nobody}));

        // nobody can send ether
        await expectThrow(instance.sendTransaction({from: role.participant1, value: 123}));
        await expectThrow(instance.sendTransaction({from: role.participant2, value: 123}));

        // not full amount
        await token1.transfer(instance.address, 49, {from: role.participant1});
        await expectThrow(instance.swap({from: role.nobody}));

        // not full amount
        await token2.transfer(instance.address, 19, {from: role.participant2});
        await expectThrow(instance.swap({from: role.nobody}));

        // not full amount
        await token1.transfer(instance.address, 1, {from: role.participant1});
        await expectThrow(instance.swap({from: role.nobody}));

        //success
        await token2.transfer(instance.address, 1, {from: role.participant2});
        await instance.swap({from: role.nobody});

        assert.equal(50, await token1.balanceOf(role.participant2));
        assert.equal(20, await token2.balanceOf(role.participant1));

        //no second swap
        await expectThrow(instance.swap({from: role.participant1}));
        await expectThrow(instance.swap({from: role.participant2}));

    });

    it("swap more than expected", async function() {

        assert.equal(0, await token1.balanceOf(role.participant2));
        assert.equal(0, await token2.balanceOf(role.participant1));


        await token1.transfer(instance.address, 51, {from: role.participant1});
        await token2.transfer(instance.address, 21, {from: role.participant2});

        await instance.swap({from: role.participant1});

        assert.equal(51, await token1.balanceOf(role.participant2));
        assert.equal(21, await token2.balanceOf(role.participant1));
    });

    it("refund", async function() {

        // p1
        assert.equal(100, await token1.balanceOf(role.participant1));
        await token1.transfer(instance.address, 51, {from: role.participant1});
        assert.equal(49, await token1.balanceOf(role.participant1));
        await expectThrow(instance.refund({from: role.nobody}));
        await instance.refund({from: role.participant1});
        assert.equal(100, await token1.balanceOf(role.participant1));

        // p2
        assert.equal(100, await token2.balanceOf(role.participant2));
        await token2.transfer(instance.address, 51, {from: role.participant2});
        assert.equal(49, await token2.balanceOf(role.participant2));
        await expectThrow(instance.refund({from: role.nobody}));
        await instance.refund({from: role.participant2});
        assert.equal(100, await token2.balanceOf(role.participant2));
    });

    it("refund after swap", async function() {

        await token1.transfer(instance.address, 51, {from: role.participant1});
        await token2.transfer(instance.address, 51, {from: role.participant2});
        await instance.swap({from: role.participant2});

        // p1
        assert.equal(49, await token1.balanceOf(role.participant1));
        await token1.transfer(instance.address, 10, {from: role.participant1});
        assert.equal(39, await token1.balanceOf(role.participant1));
        await expectThrow(instance.refund({from: role.nobody}));
        await instance.refund({from: role.participant1});
        assert.equal(49, await token1.balanceOf(role.participant1));

        // p2
        assert.equal(49, await token2.balanceOf(role.participant2));
        await token2.transfer(instance.address, 10, {from: role.participant2});
        assert.equal(39, await token2.balanceOf(role.participant2));
        await expectThrow(instance.refund({from: role.nobody}));
        await instance.refund({from: role.participant2});
        assert.equal(49, await token2.balanceOf(role.participant2));
    });

});
