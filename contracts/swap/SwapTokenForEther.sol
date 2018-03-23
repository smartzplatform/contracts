/**
 * Copyright (C) 2018  Smartz, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).
 */

pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20Basic.sol";

/**
 * @title SwapTokenForEther
 * Swap tokens of participant1 for ether of participant2
 *
 * @author Vladimir Khramov <vladimir.khramov@smartz.io>
 */
contract SwapTokenForEther {

    address public participant1;
    address public participant2;

    ERC20Basic participant1Token;
    uint256 participant1TokensCount;

    uint256 participant2EtherCount;

    bool public isFinished = false;


    function SwapTokenForEther(
        address _participant1,
        address _participant1TokenAddress,
        uint256 _participant1TokensCount,
        address _participant2,
        uint256 _participant2EtherCount
    ) public {
        require(_participant1 != _participant2);
        require(_participant1TokenAddress != address(0));
        require(_participant1TokensCount > 0);
        require(_participant2EtherCount > 0);

        participant1 = _participant1;
        participant2 = _participant2;

        participant1Token = ERC20Basic(_participant1TokenAddress);
        participant1TokensCount = _participant1TokensCount;

        participant2EtherCount = _participant2EtherCount;
    }

    /**
     * Ether accepted
     */
    function () external payable {
        require(!isFinished);
        require(msg.sender == participant2);

        if (msg.value > participant2EtherCount) {
            msg.sender.transfer(msg.value - participant2EtherCount);
        }
    }

    /**
     * Swap tokens for ether
     */
    function swap() external {
        require(!isFinished);

        require(this.balance >= participant2EtherCount);

        uint256 tokensBalance = participant1Token.balanceOf(this);
        require(tokensBalance >= participant1TokensCount);

        isFinished = true;

        participant1Token.transfer(participant2, participant1TokensCount);
        if (tokensBalance > participant1TokensCount) {
            participant1Token.transfer(participant1, tokensBalance - participant1TokensCount);
        }

        participant1.transfer(this.balance);
    }

    /**
     * Refund tokens or ether by participants
     */
    function refund() external {
        if (msg.sender == participant1) {
            uint256 tokensBalance = participant1Token.balanceOf(this);
            require(tokensBalance>0);

            participant1Token.transfer(participant1, tokensBalance);
        } else if (msg.sender == participant2) {
            require(this.balance > 0);
            participant2.transfer(this.balance);
        } else {
            revert();
        }
    }
}