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

pragma solidity ^0.4.20;

import '../Booking.sol';

/**
 * @title Booking
 * @author Vladimir Khramov <vladimir.khramov@smartz.io>
 */
contract BookingHelper is Booking {

    function BookingHelper(
        string _description,
        string _fileUrl,
        bytes32 _fileHash,
        uint256 _price,
        uint256 _penalty,
        uint256 _rentDateStart,
        uint256 _rentDateEnd,
        uint256 _noCancelPeriod,
        uint256 _acceptObjectPeriod
    ) public payable
    Booking(
        _description,
        _fileUrl,
        _fileHash,
        _price,
        _penalty,
        _rentDateStart,
        _rentDateEnd,
        _noCancelPeriod,
        _acceptObjectPeriod
    )
    {


    }

    uint m_date;

    function setTime(uint _date) public {
        m_date = _date;
    }


    function setState(State _state) public {
        m_state = _state;
    }

    ///////////////

    function getCurrentTime() public view returns (uint256) {
        return m_date;
    }
}