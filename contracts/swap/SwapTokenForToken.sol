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

    ERC20Basic participant1TokenAddress;
    uint256 participant1TokensCount;

    ERC20Basic participant2TokenAddress;
    uint256 participant2TokensCount;

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
        require(_participant1TokenAddress != address(0));
        require(_participant2TokenAddress != address(0));
        require(_participant1TokensCount > 0);
        require(_participant2TokensCount > 0);

        participant1 = _participant1;
        participant2 = _participant2;

        participant1TokenAddress = ERC20Basic(_participant1TokenAddress);
        participant1TokensCount = _participant1TokensCount;

        participant2TokenAddress = ERC20Basic(_participant2TokenAddress);
        participant2TokensCount = _participant2TokensCount;
    }

    function() external {
        revert();
    }

    function swap() external {
        require(!isFinished);

        uint256 tokens1Balance = participant1TokenAddress.balanceOf(this);
        require(tokens1Balance >= participant1TokensCount);

        uint256 tokens2Balance = participant2TokenAddress.balanceOf(this);
        require(tokens2Balance >= participant2TokensCount);

        participant1TokenAddress.transfer(participant2, tokens1Balance);
        participant2TokenAddress.transfer(participant1, tokens2Balance);

        isFinished=true;
    }

    function refund() external {
        if (msg.sender==participant1) {
            uint256 tokens1Balance = participant1TokenAddress.balanceOf(this);
            require(tokens1Balance>0);

            participant1TokenAddress.transfer(participant1, tokens1Balance);
        } else if (msg.sender==participant2) {
            uint256 tokens2Balance = participant2TokenAddress.balanceOf(this);
            require(tokens2Balance>0);

            participant2TokenAddress.transfer(participant2, tokens2Balance);
        } else {
            revert();
        }
    }
}