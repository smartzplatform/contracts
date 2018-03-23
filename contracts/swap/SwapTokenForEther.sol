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
 * @title SwapTokenForEther
 * Swap tokens of participant1 for ether of participant2
 *
 * @author Vladimir Khramov <vladimir.khramov@smartz.io>
 */
contract SwapTokenForEther is SwapBase {

    Participant public participant1;


    address public participant2;
    uint256 public participant2EtherCount;

    bool public isFinished = false;

    /**
     * Constructor
     */
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

        participant1 = Participant(_participant1, ERC20Basic(_participant1TokenAddress), _participant1TokensCount);

        participant2 = _participant2;
        participant2EtherCount = _participant2EtherCount;
    }

    function () external payable {
        require(!isFinished);
        require(msg.sender == participant2);

        if (msg.value > participant2EtherCount) {
            msg.sender.transfer(msg.value - participant2EtherCount);
        }
    }

    function swap() external {
        require(!isFinished);

        require(this.balance >= participant2EtherCount);

        uint256 tokensBalance = participant1.tokenAddr.balanceOf(this);
        require(tokensBalance >= participant1.tokensCount);

        isFinished = true;

        participant1.tokenAddr.transfer(participant2, participant1.tokensCount);
        if (tokensBalance > participant1.tokensCount) {
            participant1.tokenAddr.transfer(participant1.addr, tokensBalance - participant1.tokensCount);
        }

        participant1.addr.transfer(this.balance);
    }

    function refund() external {
        if (msg.sender == participant1.addr) {
            uint256 tokensBalance = participant1.tokenAddr.balanceOf(this);
            require(tokensBalance>0);

            participant1.tokenAddr.transfer(participant1.addr, tokensBalance);
        } else if (msg.sender == participant2) {
            require(this.balance > 0);
            participant2.transfer(this.balance);
        } else {
            revert();
        }
    }
}