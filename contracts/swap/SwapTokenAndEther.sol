// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20Basic.sol";

/**
 * @title SwapTokenAndEther
 * Swap tokens from participant1 to ether of participant2
 *
 * @author Vladimir Khramov <vladimir.khramov@smartz.io>
 */
contract SwapTokenAndEther {

    address public participant1;
    address public participant2;

    ERC20Basic participant1TokenAddress;
    uint256 participant1TokensCount;

    uint256 participant2EtherCount;

    bool public isFinished = false;


    function SwapTokenAndEther(
        address _participant1,
        address _participant1TokenAddress,
        uint256 _participant1TokensCount,
        address _participant2,
        uint256 _participant2EtherCount
    ) public {
        participant1 = _participant1;
        participant2 = _participant2;

        participant1TokenAddress = ERC20Basic(_participant1TokenAddress);
        participant1TokensCount = _participant1TokensCount;

        participant2EtherCount = _participant2EtherCount;
    }

    function swap() external {
        require(!isFinished);
        require(msg.sender==participant1 || msg.sender==participant2);

        require(this.balance>=participant2EtherCount);

        uint256 tokensBalance = participant1TokenAddress.balanceOf(this);
        require(tokensBalance>=participant1TokensCount);

        participant1TokenAddress.transfer(participant2, tokensBalance);
        participant1.transfer(this.balance);

        isFinished=true;
    }

    function () external payable {
        require(!isFinished);
        require(msg.sender==participant2);
    }

    function refund() external {
        if (msg.sender==participant1) {
            uint256 tokensBalance = participant1TokenAddress.balanceOf(this);
            require(tokensBalance>0);

            participant1TokenAddress.transfer(participant1, tokensBalance);
        } else if (msg.sender==participant2) {
            require(this.balance>=0);
            participant2.transfer(this.balance);
        } else {
            revert();
        }
    }
}