'use strict';

import expectThrow from '../helpers/expectThrow';


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
		assert.equal(await instance.balanceOf(roles.owner1), 100);
		// check owner2 equity balance == 0 (new owner)
		assert.equal(await instance.balanceOf(roles.owner2), 0);

		// check owner1 ether balance == 0
		assert.equal(await instance.etherBalanceOf(roles.owner1), 0);

		// now owner1 tries to send 40 EQT to owner2 (not added to list of owners)
		await expectThrow(instance.transfer(roles.owner2, 40, {from: roles.owner1}));


		// now owner2 tries to add itself to owners_list, but only owners are allowed to add
		// other owners and must transfer at least 1 token
		await expectThrow(instance.addOwner(roles.owner2, 80, {from: roles.owner2}));

		await instance.addOwner(roles.owner2, 1, {from: roles.owner1});

		await displayEquityState(instance);


/*

		// check owner2 ether balance == 0
		assert.equal(await instance.etherBalanceOf(roles.owner2),0);
		// await displayEquityState(instance);

		await displayEquityState(instance);

		// [STEP] receive funds. All 100% of funds must be transfered to owner1's balance (he owns 100% of tokens)
		let firstPayment = web3.toWei(1, "ether");
		await instance.send(firstPayment, {from: roles.extrn1})
		// now, ether balance of owner1 must be "firstPayment"
		assert.equal(await instance.etherBalanceOf(roles.owner1), firstPayment);

		await displayEquityState(instance);

		// [STEP] transfer part of "MAX_EQUITY_TOKENS" from owner1 to owner2
		let firstTokensTransferred = 33;
		await instance.transfer(roles.owner2, firstTokensTransferred, {from: roles.owner1})
		assert.equal(await instance.balanceOf(roles.owner1), MAX_EQUITY_TOKENS - firstTokensTransferred);
		assert.equal(await instance.balanceOf(roles.owner2), firstTokensTransferred);
		
		await displayEquityState(instance);

		// [STEP] receive funds. Now 60% goes to owner1, 40% to owner2
		let secondPayment = web3.toWei(1, "ether");
		await instance.send(secondPayment, {from: roles.extrn2})
		// now, ether balance of owner1 must +100 finney
		let owner1NowBalance = await instance.etherBalanceOf(roles.owner1);
		let owner2NowBalance = await instance.etherBalanceOf(roles.owner2);

		let owner1NewBalance = +firstPayment + +(secondPayment * (MAX_EQUITY_TOKENS - firstTokensTransferred) / MAX_EQUITY_TOKENS);
		let owner2NewBalance = secondPayment * firstTokensTransferred / MAX_EQUITY_TOKENS;
		assert.equal(+owner1NowBalance, +owner1NewBalance);
		assert.equal(+owner2NowBalance, +owner2NewBalance);

		await displayEquityState(instance);

		// [STEP] withdraw funds. Now 60% goes to owner1, 40% to owner2

		// extrn2 tries to withdraw funds, fuck him
		await expectThrow(instance.withdraw(web3.toWei(0.5, "ether"), {from: roles.extrn2}));
		// owner1 tries to withdraw more funds, than he owns
		await expectThrow(instance.withdraw(web3.toWei(666, "ether"), {from: roles.owner1}));

		// owner1 and owner2 both tries to withdraw normal amount of funds
		let owner1FirstWithdraw = web3.toWei(0.3, "ether");
		let owner2FirstWithdraw = web3.toWei(0.1, "ether");

		await instance.withdraw(owner1FirstWithdraw, {from: roles.owner1});
		await instance.withdraw(owner2FirstWithdraw, {from: roles.owner2});
		
		let owner1LastBalance = await instance.etherBalanceOf(roles.owner1);
		let owner2LastBalance = await instance.etherBalanceOf(roles.owner2);

		assert.equal(owner1LastBalance, +owner1NewBalance - owner1FirstWithdraw);
		assert.equal(owner2LastBalance, +owner2NewBalance - owner2FirstWithdraw);

		await displayEquityState(instance);
*/

    });







});
