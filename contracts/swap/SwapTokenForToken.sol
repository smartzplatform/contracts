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
import "./SwapBase.sol";

/**
 * @title SwapTokenForToken
 * Swap tokens of participant1 for tokens of participant2
 *
 * @author Vladimir Khramov <vladimir.khramov@smartz.io>
 */
contract SwapTokenForToken is SwapBase {

    Participant public participant1;
    Participant public participant2;

    bool public isFinished = false;

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

        participant1 = Participant(_participant1, ERC20Basic(_participant1TokenAddress), _participant1TokensCount);
        participant2 = Participant(_participant2, ERC20Basic(_participant2TokenAddress), _participant2TokensCount);
    }

    function() external {
        revert();
    }

    function swap() external {
        require(!isFinished);

        uint256 tokens1Balance = participant1.tokenAddr.balanceOf(this);
        require(tokens1Balance >= participant1.tokensCount);

        uint256 tokens2Balance = participant2.tokenAddr.balanceOf(this);
        require(tokens2Balance >= participant2.tokensCount);

        isFinished = true;

        participant1.tokenAddr.transfer(participant2.addr, participant1.tokensCount);
        if (tokens1Balance > participant1.tokensCount) {
            participant1.tokenAddr.transfer(participant1.addr, tokens1Balance - participant1.tokensCount);
        }

        participant2.tokenAddr.transfer(participant1.addr, participant2.tokensCount);
        if (tokens2Balance > participant2.tokensCount) {
            participant2.tokenAddr.transfer(participant2.addr, tokens2Balance - participant2.tokensCount);
        }
    }

    function refund() external {
        if (msg.sender == participant1.addr) {
            uint256 tokens1Balance = participant1.tokenAddr.balanceOf(this);
            require(tokens1Balance > 0);

            participant1.tokenAddr.transfer(participant1.addr, tokens1Balance);
        } else if (msg.sender == participant2.addr) {
            uint256 tokens2Balance = participant2.tokenAddr.balanceOf(this);
            require(tokens2Balance > 0);

            participant2.tokenAddr.transfer(participant2.addr, tokens2Balance);
        } else {
            revert();
        }
    }
}