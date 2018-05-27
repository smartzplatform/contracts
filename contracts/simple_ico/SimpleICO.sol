/**
 * Copyright (C) 2018 Smartz, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).
 */


pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/MintableToken.sol';
import 'zeppelin-solidity/contracts/token/BurnableToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';


contract Token is MintableToken, BurnableToken
{
    string public constant name = 'My token';
    string public constant symbol = 'MTK';
    uint8 public constant decimals = 18;

    function Token() public {

    }

}

contract ICO
{
    using SafeMath for uint256;

    Token public token;
    uint256 public collected;
    uint256 public date_start = 1527454800;
    uint256 public date_end = 1527714000;
    uint256 public hard_cap = 1000 ether;
    uint256 public rate = 1000;
    address public funds_address = address(0x627306090abaB3A6e1400e9345bC60c78a8BEf57);

    function ICO() public payable {
        token = new Token();
    }

    function () public payable {
        require(now >= date_start && now <= date_end && collected.add(msg.value)<hard_cap);
        token.mint(msg.sender, msg.value.mul(rate));
        funds_address.transfer(msg.value);
        collected = collected.add(msg.value);
    }

    function totalTokens() public view returns (uint) {
        return token.totalSupply();
    }

    function daysRemaining() public view returns (uint) {
        if (now > date_end) {
            return 0;
        }
        return date_end.sub(now).div(1 days);
    }

    function collectedEther() public view returns (uint) {
        return collected.div(1 ether);
    }
}
