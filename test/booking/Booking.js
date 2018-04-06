'use strict';


import {finney} from "../helpers/ether";
import assertBnEq from "../helpers/assertBigNumbersEqual";
import getBalance from "../helpers/getBalance";
import {withRollback} from "../helpers/EVMSnapshots";
import expectThrow from "../helpers/expectThrow";


const Booking = artifacts.require("BookingHelper.sol");
const l = console.log;

contract('Booking', function(accounts) {

    const role =  {
		owner: accounts[1],
		client: accounts[2],
        nobody: accounts[3],
	};

    const state = {
        OFFER: 0,
        PAID: 1,
        NO_CANCEL: 2,
        RENT: 3,
        FINISHED: 4
    };

    let instance, dateStart, dateEnd, noCancelPeriod, acceptObjectPeriod;

    beforeEach(async function() {
        dateStart = (new Date())/1000 + 24*3600;
        dateEnd   = (new Date())/1000 + 3*24*3600;
        noCancelPeriod = acceptObjectPeriod = 60*60;

        instance = await Booking.new(
            'Tverskaya 12, appartment 172, 5th floor',
            'http://yandex.ru',
            'sdsd',
            finney(1),
            finney(0.2),
            dateStart,
            dateEnd,
            noCancelPeriod,
            acceptObjectPeriod,
            {
                from: role.owner
            }
        );
    });

    it("check payment", async function() {
        await instance.setTime(dateStart-1);
        await expectThrow(instance.sendTransaction({value: finney(0.9)}));

        let initClientBalance = await web3.eth.getBalance(role.client);
        await instance.sendTransaction({gasPrice: 0, value: finney(1.1), from: role.client});
        assertBnEq(
            initClientBalance.sub(finney(1)),
            await getBalance(role.client),
            "change sent back"
        );

        assert.equal(role.client, await instance.m_client())
    });

    it("check payment after date start", async function() {
        await instance.setTime(dateStart+1);
        await expectThrow(instance.sendTransaction({value: finney(1)}));
    });

    it("check second payment", async function() {
        await instance.setTime(dateStart-1);

        await instance.sendTransaction({value: finney(1)});
        await expectThrow(instance.sendTransaction({value: finney(1)}));
    });

    it("check state", async function() {
        await instance.setState(state.PAID);
        await instance.setTime(dateStart - noCancelPeriod - 1);

        assert.equal(state.PAID, await instance.getCurrentState());

        await instance.setTime(dateStart - noCancelPeriod + 1);
        assert.equal(state.NO_CANCEL, await instance.getCurrentState());

    });

    it("reject payment", async function() {
        await instance.setTime(dateStart-1-noCancelPeriod);
        await instance.sendTransaction({value: finney(1), from: role.client});

        await expectThrow( instance.rejectPayment({from: role.nobody}) );
        await expectThrow( instance.rejectPayment({from: role.client}) );

        assert.equal(state.PAID, await instance.getCurrentState());

        let initClientBalance = await web3.eth.getBalance(role.client);
        await instance.rejectPayment({from: role.owner});
        assert.equal(state.OFFER, await instance.getCurrentState());
        assertBnEq(
            initClientBalance.add(finney(1)),
            await getBalance(role.client),
            "sent back after reject"
        );

        assert.equal(0, await instance.m_client());

    });

    it("refund payment", async function() {
        await instance.setTime(dateStart-1-noCancelPeriod);
        await instance.sendTransaction({value: finney(1), from: role.client});

        await expectThrow( instance.rejectPayment({from: role.nobody}) );
        await expectThrow( instance.rejectPayment({from: role.client}) );

        assert.equal(state.PAID, await instance.getCurrentState());

        let initClientBalance = await web3.eth.getBalance(role.client);
        await instance.refund({gasPrice: 0, from: role.client});
        assert.equal(state.OFFER, await instance.getCurrentState());
        assertBnEq(
            initClientBalance.add(finney(1)),
            await getBalance(role.client),
            "sent back after refund"
        );

        assert.equal(0, await instance.m_client());


        await instance.sendTransaction({value: finney(1), from: role.client});
        await instance.setState(state.NO_CANCEL);
        await expectThrow(instance.refund({from: role.client}));

        await instance.setState(state.RENT);
        await expectThrow(instance.refund({from: role.client}));

        await instance.setState(state.FINISHED);
        await expectThrow(instance.refund({from: role.client}));

        await instance.setState(state.PAID);
        await instance.refund({from: role.client});
    });


    it("successful rent", async function() {
        let initClientBalance = await web3.eth.getBalance(role.client);
        let initOwnerBalance  = await web3.eth.getBalance(role.owner);


        await instance.setTime(dateStart-noCancelPeriod-1);
        await instance.sendTransaction({gasPrice: 0, value: finney(1), from: role.client});

        assert.equal(state.PAID, await instance.getCurrentState());

        await instance.setTime(dateStart-noCancelPeriod+1);
        assert.equal(state.NO_CANCEL, await instance.getCurrentState());
        await expectThrow(instance.startRent({gasPrice: 0, from: role.client}));

        await instance.setTime(dateStart+1);
        await instance.startRent({gasPrice: 0, from: role.client});
        assert.equal(state.RENT, await instance.getCurrentState());

        await instance.setTime(dateEnd+1);
        assert.equal(state.FINISHED, await instance.getCurrentState());


        assertBnEq(
            initClientBalance.sub(finney(1)),
            await getBalance(role.client),
            "result client balance"
        );
        assertBnEq(
            initOwnerBalance.add(finney(1)),
            await getBalance(role.owner),
            "result owner balance"
        );
    });


    it("bad object (refund by client)", async function() {
        const assertCorrectCancel = async (msg) => {
            assert.equal(state.OFFER, await instance.getCurrentState(), msg);
            assertBnEq(initClientBalance.sub(finney(0.2)), await getBalance(role.client), "result client balance: "+msg);
            assertBnEq(initOwnerBalance.add(finney(0.2)), await getBalance(role.owner), "result owner balance: "+msg);
        };

        let initClientBalance = await web3.eth.getBalance(role.client);
        let initOwnerBalance  = await web3.eth.getBalance(role.owner);


        await instance.setTime(dateStart-noCancelPeriod-1);
        await instance.sendTransaction({gasPrice: 0, value: finney(1), from: role.client});

        assert.equal(state.PAID, await instance.getCurrentState());

        let dates = [
            dateStart-noCancelPeriod+1,
            dateStart-1,
            dateStart+1,
            dateStart+acceptObjectPeriod - 1
        ];
        for (let date of dates) {
            await withRollback(async () => {
                await instance.setTime(date);
                assert.equal(state.NO_CANCEL, await instance.getCurrentState());
                await instance.cancelBooking({gasPrice: 0, from: role.client});

                await assertCorrectCancel(date);
            });
        }

        await instance.setTime(dateStart+acceptObjectPeriod + 1);
        assert.equal(state.NO_CANCEL, await instance.getCurrentState());
        await expectThrow(instance.cancelBooking({gasPrice: 0, from: role.client}));

    });

    it("bad object (refund by owner)", async function() {
        const assertCorrectCancel = async (msg) => {
            assert.equal(state.OFFER, await instance.getCurrentState(), msg);
            assertBnEq(initClientBalance.sub(finney(0.2)), await getBalance(role.client), "result client balance: "+msg);
            assertBnEq(initOwnerBalance.add(finney(0.2)), await getBalance(role.owner), "result owner balance: "+msg);
        };

        let initClientBalance = await web3.eth.getBalance(role.client);
        let initOwnerBalance  = await web3.eth.getBalance(role.owner);

        await instance.setTime(dateStart-noCancelPeriod-1);
        await instance.sendTransaction({gasPrice: 0, value: finney(1), from: role.client});

        assert.equal(state.PAID, await instance.getCurrentState());

        let dates = [
            dateStart-noCancelPeriod+1,
            dateStart-1,
            dateStart+1,
            dateStart+acceptObjectPeriod - 1
        ];
        for (let date of dates) {
            await withRollback(async () => {
                await instance.setTime(date);
                assert.equal(state.NO_CANCEL, await instance.getCurrentState());
                await instance.cancelBooking({gasPrice: 0, from: role.client});

                await expectThrow(instance.cancelBooking({gasPrice: 0, from: role.owner}));
            });
        }

        await instance.setTime(dateStart+acceptObjectPeriod + 1);
        assert.equal(state.NO_CANCEL, await instance.getCurrentState());
        await instance.cancelBooking({gasPrice: 0, from: role.owner});
        await assertCorrectCancel('');

    });

});
