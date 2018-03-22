/**
 * Copyright (C) 2017-2018  Smartz, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).
 */
pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

/**
 * @title EquityPoolToken
 * @author boogerwooger <sergey@mixbytes.io>
 * @dev Contract for distributing 100 tokens as percents between several
 participants. All incoming pays distribute between participants,according
 to their tokens' balances. Any owner can withdraw his balance.
 */
contract EquityPoolToken {
	using SafeMath for uint256;

	// using exact 100 tokens denies all float values, so you cannot have 4.34 % 
	uint8 constant maxEquityTokens = 100;
	uint8 constant maxOwners = 100;

	struct Owner {
		address addr;
    	uint256 ether_balance;
		uint8 equity_balance;
	}

	/**
 	 * @dev Main array of Owners structs. In this minimalistic variant of EquityPoolToken
	 it's the one, single source of data. All methods use array iterations to find owners.
 	 */
	Owner[] owners;	

	/**
 	 * @dev Initializes first Owner{} struct in owners[] array;
 	 */
	function EquityPoolToken()
		public
	{
		owners.push(Owner({addr: msg.sender, ether_balance: 0, equity_balance: maxEquityTokens}));
    }

	event NewOwner(address _new_owner, uint8 _new_amount);

	/**
 	 * @dev One of owners adds new owner and gives him some amount of his tokens. New
	 owner begins with zero ether balance, but, having non-zero equity balance, will
	 receive correspondig part of all next incoming pays
 	 */
	function addOwner(address _new_owner, uint8 _new_amount) public returns (bool){
		require (msg.sender != _new_owner);
		require (_new_amount > 0 && _new_amount < maxEquityTokens);
		require (owners.length < maxOwners);

        for (uint8 i=0; i < owners.length; i++) {
            if (owners[i].addr == _new_owner) {
				revert();
            }
		}
        for (i = 0; i < owners.length; i++) {
			if (owners[i].addr == msg.sender) {
				require(owners[i].equity_balance >= _new_amount);
				owners[i].equity_balance -= _new_amount;
				owners.push(Owner({addr: _new_owner, ether_balance: 0, equity_balance: _new_amount}));
				NewOwner(_new_owner, _new_amount);
				return true;
			}
		}
		revert();
    }

	/**
 	 * @dev Transfers equity tokens between owners
 	 */
	function transfer(address _to, uint8 _amount) public returns (bool){
		require(_to != 0x0);
		require(_amount > 0 && _amount <= maxEquityTokens);

		// find two indexes in array - sender and recipient
		uint8 _fromInd = maxOwners;
		uint8 _toInd = maxOwners;

		for (uint8 i = 0; i < owners.length; i++) {
			if (_fromInd == maxOwners && msg.sender == owners[i].addr) {
				_fromInd = i;
			}
			if (_toInd == maxOwners && owners[i].addr == _to) {
				_toInd = i;
			}
			// [TODO] stop execution if both indexes found, if estimated gaz is lower
		}

		require(_fromInd >= 0 && _fromInd < maxOwners);
		require(_toInd >= 0 && _toInd < maxOwners);
		require(_amount <= owners[_fromInd].equity_balance);

		owners[_fromInd].equity_balance -= _amount;
		owners[_toInd].equity_balance += _amount;

		return true;
	}

	/**
 	 * @dev Incoming payment is distributed to token owners' ether balances. They can withdraw it later
 	 */
    function () public payable {
        require (msg.value > 0);
        // every equity balance is a percentage of ether distributuion
		// between all equity token owners
        uint256 undistributedSum = msg.value;
        
        for (uint8 i = 0; i < owners.length; i++) {
            uint256 valueToAdd = msg.value * owners[i].equity_balance / maxEquityTokens;
            undistributedSum -= valueToAdd;
            owners[i].ether_balance += valueToAdd;
        }

		require(i == owners.length);
		// [TODO] check here for rounding errors
     	require(undistributedSum == 0);   
    }

	/**
 	 * @dev Owner withdraws his ether from his balance
 	 */
	function withdraw(uint256 _amount) public returns (bool) {
		require(_amount > 0);
        for (uint8 i = 0; i < owners.length; i++) {
			if (owners[i].addr != msg.sender) {
				continue;
			}

			assert(owners[i].addr == msg.sender);
			require(_amount <= owners[i].ether_balance);

			owners[i].ether_balance -= _amount;
        	msg.sender.transfer(_amount);
			return true;
		}
		revert();
	}

    /// @return returns equity_tokens balance by address. Returns 0 if not found
	function balanceOf(address _who) public view returns (uint8) {
		for (uint8 i=0; i < owners.length; i++) {
			if (owners[i].addr == _who) {
				return owners[i].equity_balance;
			}
		}
		return 0;
	}

    /// @return returns equity_tokens balance by address. Returns 0 if not found
	function etherBalanceOf(address _who) public view returns (uint256) {
		for (uint8 i=0; i < owners.length; i++) {
			if (owners[i].addr == _who) {
				return owners[i].ether_balance;
			}
		}
		return 0;
	}

}
