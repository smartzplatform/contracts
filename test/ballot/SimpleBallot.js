'use strict';

import expectThrow from '../helpers/expectThrow';


const SimpleBallot = artifacts.require("SimpleBallot.sol");
const l = console.log;

contract('SimpleBallot', function(accounts) {

    const role =  {
		addr1: accounts[0],
		addr2: accounts[1],
        addr3: accounts[2],
        addr4: accounts[3],
        addr5: accounts[4],
        addr6: accounts[5]
	};

    let instance;

    beforeEach(async function() {
        instance = await SimpleBallot.new( );
    });

    it("test bounds", async function() {
        await expectThrow(instance.vote(0, {from: role.addr1}));
        await expectThrow(instance.vote(4, {from: role.addr1}));

        await expectThrow(instance.voteByName('', {from: role.addr1}));
        await expectThrow(instance.voteByName('Not a city', {from: role.addr1}));

    });

	it("test only one vote", async function() {
        await instance.vote(1, {from: role.addr1});
        await expectThrow(instance.vote(1, {from: role.addr1}));
        await expectThrow(instance.vote(2, {from: role.addr1}));
        await instance.vote(1, {from: role.addr2});

    });


    it("complex test", async function() {

        let winnerDescr = await instance.getWinner();
        assert.equal(1, winnerDescr[0]);
        assert.equal('Moscow', winnerDescr[1]);
        assert.equal(0, winnerDescr[2]);
        assert.equal(0, await instance.getVotesCount(1));
        assert.equal(0, await instance.getVotesCount(2));
        assert.equal(0, await instance.getVotesCount(3));
        assert.equal(0, await instance.getVotesCountByName('Moscow'));
        assert.equal(0, await instance.getVotesCountByName('New York'));
        assert.equal(0, await instance.getVotesCountByName('London'));

        await instance.vote(2, {from: role.addr1});
        winnerDescr = await instance.getWinner();
        assert.equal(2, winnerDescr[0]);
        assert.equal('New York', winnerDescr[1]);
        assert.equal(1, winnerDescr[2]);
        assert.equal(0, await instance.getVotesCount(1));
        assert.equal(1, await instance.getVotesCount(2));
        assert.equal(0, await instance.getVotesCount(3));
        assert.equal(0, await instance.getVotesCountByName('Moscow'));
        assert.equal(1, await instance.getVotesCountByName('New York'));
        assert.equal(0, await instance.getVotesCountByName('London'));

        await instance.vote(3, {from: role.addr2});
        winnerDescr = await instance.getWinner();
        assert.equal(2, winnerDescr[0]);
        assert.equal('New York', winnerDescr[1]);
        assert.equal(1, winnerDescr[2]);
        assert.equal(0, await instance.getVotesCount(1));
        assert.equal(1, await instance.getVotesCount(2));
        assert.equal(1, await instance.getVotesCount(3));
        assert.equal(0, await instance.getVotesCountByName('Moscow'));
        assert.equal(1, await instance.getVotesCountByName('New York'));
        assert.equal(1, await instance.getVotesCountByName('London'));

        await instance.voteByName('Moscow', {from: role.addr3});
        winnerDescr = await instance.getWinner();
        assert.equal(1, winnerDescr[0]);
        assert.equal('Moscow', winnerDescr[1]);
        assert.equal(1, winnerDescr[2]);
        assert.equal(1, await instance.getVotesCount(1));
        assert.equal(1, await instance.getVotesCount(2));
        assert.equal(1, await instance.getVotesCount(3));
        assert.equal(1, await instance.getVotesCountByName('Moscow'));
        assert.equal(1, await instance.getVotesCountByName('New York'));
        assert.equal(1, await instance.getVotesCountByName('London'));

        await instance.voteByName('New York', {from: role.addr4});
        winnerDescr = await instance.getWinner();
        assert.equal(2, winnerDescr[0]);
        assert.equal('New York', winnerDescr[1]);
        assert.equal(2, winnerDescr[2]);
        assert.equal(1, await instance.getVotesCount(1));
        assert.equal(2, await instance.getVotesCount(2));
        assert.equal(1, await instance.getVotesCount(3));
        assert.equal(1, await instance.getVotesCountByName('Moscow'));
        assert.equal(2, await instance.getVotesCountByName('New York'));
        assert.equal(1, await instance.getVotesCountByName('London'));
    });



});
