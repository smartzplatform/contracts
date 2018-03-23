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
contract SwapBase {

    struct Participant {
        address addr;
        ERC20Basic tokenAddr;
        uint256 tokensCount;
    }

}