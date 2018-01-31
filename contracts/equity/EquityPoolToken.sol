// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

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

	Owner[] owners;	

	function EquityPoolToken()
		public
	{
		owners.push(Owner({addr: msg.sender, ether_balance: 0, equity_balance: maxEquityTokens}));
    }

	// FIXME visiblities
	// FIXME names

	function addOwner(address _new_owner, uint8 _new_amount) public returns (bool){
		// TODO addUser kvorum
		require (owners.length < maxOwners);
		
        for (uint8 i=0; i < owners.length; i++) {
            if (owners[i].addr == _new_owner) {
                throw;
            }
			if (owners[i].addr == msg.sender) {
				owners[i].equity_balance -= _new_amount;
				owners.push(Owner({addr: _new_owner, ether_balance: 0, equity_balance: _new_amount}));
				return true;
			}
		}
    }

	function transfer(address _to, uint8 _amount) public returns (bool){
		require(_amount > 0 && _amount <= maxEquityTokens);
		// FIXME add checks
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


    function () public payable {
        require (msg.value > 0);
        // every equity balance is a percentage of ether distributuion
        // as percentage, when dividing incoming ether
        uint256 undistributedSum = msg.value;

        // TODO defend against gaz lack in the middle of cycle
        
        for (uint8 i = 0; i < owners.length; i++) {
            uint256 valueToAdd = msg.value * owners[i].equity_balance / 100;
            undistributedSum -= valueToAdd;
            owners[i].ether_balance += valueToAdd;
        }
        // TODO rounding, deal with rest in 
     	assert(undistributedSum == 0);   
    }

	function withdraw(uint256 _amount) public returns (bool) {
		require(_amount > 0);
        for (uint8 i = 0; i < owners.length; i++) {
			if (owners[i].addr != msg.sender) {
				continue;
			}
			require(_amount <= owners[i].ether_balance);
			owners[i].ether_balance -= _amount;
        	msg.sender.transfer(_amount);
			return true;
		}
		throw;
	}
	// HZZZZZZZZZZZZZZZZZZZZZzz
	/// @return The Owner
	function getOwnerByAddress(address _who) public view returns (Owner) {
		for (uint8 i=0; i < owners.length; i++) {
			if (owners[i].addr == _who) {
				return owners[i];
			}
		}
		throw;
	}


    /// @return The balance
	function balanceOf(address _who) public view returns (uint8) {
		for (uint8 i=0; i < owners.length; i++) {
			if (owners[i].addr == _who) {
				return owners[i].equity_balance;
			}
		}
		return 0;
	}

	function etherBalanceOf(address _who) public view returns (uint256) {
		for (uint8 i=0; i < owners.length; i++) {
			if (owners[i].addr == _who) {
				return owners[i].ether_balance;
			}
		}
		return 0;
	}

}
