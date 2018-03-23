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
 * @title SwapTokenForToken
 * Swap tokens of participant1 for tokens of participant2
 *
 * @author Vladimir Khramov <vladimir.khramov@smartz.io>
 */
contract SwapTokenForToken {

    address public participant1;
    address public participant2;

    ERC20Basic public participant1Token;
    uint256 public participant1TokensCount;

    ERC20Basic public participant2Token;
    uint256 public participant2TokensCount;

    bool public isFinished = false;

    /**
     * Constructor
     */
    function SwapTokenForToken(
        address _participant1,
        address _participant1TokenAddress,
        uint256 _participant1TokensCount,
        address _participant2,
        address _participant2TokenAddress,
        uint256 _participant2TokensCount
    ) public {
        require(_participant1 != _participant2);
        require(_participant1TokenAddress != _participant2TokenAddress);
        require(_participant1TokenAddress != address(0));
        require(_participant2TokenAddress != address(0));
        require(_participant1TokensCount > 0);
        require(_participant2TokensCount > 0);

        participant1 = _participant1;
        participant2 = _participant2;

        participant1Token = ERC20Basic(_participant1TokenAddress);
        participant1TokensCount = _participant1TokensCount;

        participant2Token = ERC20Basic(_participant2TokenAddress);
        participant2TokensCount = _participant2TokensCount;
    }

    /**
     * No direct payments
     */
    function() external {
        revert();
    }

    /**
     * Swap tokens for tokens
     */
    function swap() external {
        require(!isFinished);

        uint256 tokens1Balance = participant1Token.balanceOf(this);
        require(tokens1Balance >= participant1TokensCount);

        uint256 tokens2Balance = participant2Token.balanceOf(this);
        require(tokens2Balance >= participant2TokensCount);

        isFinished = true;

        participant1Token.transfer(participant2, participant1TokensCount);
        if (tokens1Balance > participant1TokensCount) {
            participant1Token.transfer(participant1, tokens1Balance - participant1TokensCount);
        }

        participant2Token.transfer(participant1, participant2TokensCount);
        if (tokens2Balance > participant2TokensCount) {
            participant2Token.transfer(participant2, tokens2Balance - participant2TokensCount);
        }
    }

    /**
     * Refund tokens by participants
     */
    function refund() external {
        if (msg.sender == participant1) {
            uint256 tokens1Balance = participant1Token.balanceOf(this);
            require(tokens1Balance > 0);

            participant1Token.transfer(participant1, tokens1Balance);
        } else if (msg.sender == participant2) {
            uint256 tokens2Balance = participant2Token.balanceOf(this);
            require(tokens2Balance > 0);

            participant2Token.transfer(participant2, tokens2Balance);
        } else {
            revert();
        }
    }
}