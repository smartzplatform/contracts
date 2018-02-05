'use strict';

import expectThrow from '../helpers/expectThrow';
import '../helpers/typeExt';

const EquityPoolTokenTestHelper = artifacts.require("../contracts/helpers/EquityPoolTokenTestHelper.sol");
const l = console.log;

contract('EquityPoolToken', function(accounts) {

    function getRoles() {
        return {
			owner1: accounts[0],
            owner2: accounts[1],
            owner3: accounts[2],
           	extrn1: accounts[3],
           	extrn2: accounts[4]
        };
    }
	var MAX_EQUITY_TOKENS = +100; // to force number type

	function assertBigNumberEqual(actual, expected, message=undefined) {
        assert(actual.eq(expected), "{2}expected {0}, but got: {1}".format(expected, actual, message ? message + ': ' : ''));
    }

	async function displayEquityState(instance) {
		var roles = getRoles();
		console.log("\n");
		for (var owner in roles) {
			let eqtBalance = await instance.balanceOf(roles[owner])
			let ethBalance = web3.fromWei(await instance.etherBalanceOf(roles[owner]), 'ether');
			let ownEthBalance = web3.eth.getBalance(roles[owner]);
			console.log("[EQUITY_STATE] " + owner + "(" + roles[owner] + "), balances(EQT, ETH): [" + eqtBalance + ", " + ethBalance + "], own funds: " + ownEthBalance);
		}
	}	

	it("test equity tokens creation and transfers", async function() {
        const roles = getRoles();

		// role.owner1 creates EquityPoolToken and receives 100 tokens. Now 100% of incoming Ether will be
		// tranfered to role.owner1's ether_balance (100% of money goes to owner1, because he has 100 equity tokens)

        // [STEP] Deploy contract and add first owner
		const instance = await EquityPoolTokenTestHelper.new({from: roles.owner1});

		// check owner1 equity balance == 100 EQT
		await assert.equal(await instance.balanceOf(roles.owner1), 100);
		// check owner2 equity balance == 0 (new owner)
		await assert.equal(await instance.balanceOf(roles.owner2), 0);

		// now owner1 tries to send 40 EQT to owner2 (not added to list of owners)
		await expectThrow(instance.transfer(roles.owner2, 40, {from: roles.owner1}));

		// await displayEquityState(instance);

		// now owner2 tries to add itself to owners_list, but only owners are allowed to add
		// other owners and must transfer at least 1 token

		await expectThrow(instance.addOwner(roles.owner2, 3, {from: roles.owner2}));

		await instance.addOwner(roles.owner2, 7, {from: roles.owner1});
		assert.equal(await instance.balanceOf(roles.owner2), 7);
		assert.equal(await instance.balanceOf(roles.owner1), 93);

		// owner1 repeat creation of owner2 (fail), all equity balances still the same
		await expectThrow( instance.addOwner(roles.owner2, 7, {from: roles.owner1}));

		// await displayEquityState(instance);
		// owner2 try add owner, but haven't enough tokens
		await expectThrow(instance.addOwner(roles.owner3, 15, {from: roles.owner2}));

		await instance.addOwner(roles.owner3, 2, {from: roles.owner2});
		assert.equal(await instance.balanceOf(roles.owner2), 5);
		assert.equal(await instance.balanceOf(roles.owner3), 2);
		// owner3 try to add owner1 with 1 token (fail)
		await expectThrow(instance.addOwner(roles.owner1, 1, {from: roles.owner3}));
		// await displayEquityState(instance);

    });

	it("test ether distrubution for different owners confugrations", async function() {
        const roles = getRoles();
		const instance = await EquityPoolTokenTestHelper.new({from: roles.owner1});

		// [STEP] receive funds. All 100% of funds must be transfered to owner1's balance (he owns 100% of tokens)
		assert.equal(await instance.etherBalanceOf(roles.owner2),0);
		let payment1 = web3.toWei(777, "finney");
		await instance.send(payment1, {from: roles.extrn1})

		// await displayEquityState(instance);
		// now, ether balance of owner1 must be "payment1"

		assert.equal(await instance.etherBalanceOf(roles.owner1), payment1);

		// owner1 tries to withdraw more funds he have
		await expectThrow(instance.withdraw(web3.toWei(888, "finney"), {from: roles.owner1}));
		// owner1 withdraws all balance
		await instance.withdraw(payment1, {from: roles.owner1});
		await expectThrow(instance.withdraw(web3.toWei(888, "finney"), {from: roles.owner1}));

		// owner1 add owners2 and give him some tokens
		await instance.addOwner(roles.owner2, 13, {from: roles.owner1});
		assert.equal(await instance.etherBalanceOf(roles.owner2), 0);

		// owner2 tries to withdraw small funds, but haven't any on its balance
		await expectThrow(instance.withdraw(web3.toWei(111, "finney"), {from: roles.owner2}));

		// await displayEquityState(instance);

		var payment2 = web3.toWei(100, "finney");
		await instance.send(payment2, {from: roles.extrn1});
		let owner1NewBalance = payment2  * (MAX_EQUITY_TOKENS - 13) / MAX_EQUITY_TOKENS;
		let owner2NewBalance = payment2 * 13 / MAX_EQUITY_TOKENS;
		assertBigNumberEqual(await instance.etherBalanceOf(roles.owner1), +owner1NewBalance);
		assertBigNumberEqual(await instance.etherBalanceOf(roles.owner2), +owner2NewBalance);

		// await displayEquityState(instance);

		// owner1 withdraws all invested funds
		await instance.withdraw(owner1NewBalance, {from: roles.owner1});
		assertBigNumberEqual(await instance.etherBalanceOf(roles.owner1), 0);

		// await displayEquityState(instance);

		var payment3 = web3.toWei(100, "finney");
		await instance.send(payment3, {from: roles.extrn2});
		assertBigNumberEqual(await instance.etherBalanceOf(roles.owner1), payment3  * (MAX_EQUITY_TOKENS - 13) / MAX_EQUITY_TOKENS);
		assertBigNumberEqual(await instance.etherBalanceOf(roles.owner2), +web3.toWei(13, "finney") + (payment3 * 13 / MAX_EQUITY_TOKENS));

		// await displayEquityState(instance);

    });

});
