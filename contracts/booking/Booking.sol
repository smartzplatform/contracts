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

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * @title Booking
 * @author Vladimir Khramov <vladimir.khramov@smartz.io>
 */
contract Booking is Ownable {

    function Booking(
        string _description,
        string _fileUrl,
        bytes32 _fileHash,
        uint256 _price,
        uint256 _cancellationFee,
        uint256 _rentDateStart,
        uint256 _rentDateEnd,
        uint256 _noCancelPeriod,
        uint256 _acceptObjectPeriod
    ) public payable {
        require(_price > 0);
        require(_price > _cancellationFee);
        require(_rentDateStart > getCurrentTime());
        require(_rentDateEnd > _rentDateStart);

        require(_rentDateStart+_acceptObjectPeriod < _rentDateEnd);
        require(_rentDateStart > _noCancelPeriod);

        m_description = _description;
        m_fileUrl = _fileUrl;
        m_fileHash = _fileHash;
        m_price = _price;
        m_cancellationFee = _cancellationFee;
        m_rentDateStart = _rentDateStart;
        m_rentDateEnd = _rentDateEnd;
        m_noCancelPeriod = _noCancelPeriod;
        m_acceptObjectPeriod = _acceptObjectPeriod;

    }

    /************************** STRUCTS **********************/
    enum State {OFFER, PAID, NO_CANCEL, RENT, CANCELED, FINISHED}

    /************************** MODIFIERS **********************/

    modifier onlyState(State _state) {
        require(getCurrentState() == _state);
        _;
    }

    modifier onlyClient() {
        require(msg.sender == m_client);
        _;
    }

    /************************** EVENTS **********************/

    event StateChanged(State newState);

    /************************** CONSTANTS **********************/

    /************************** PROPERTIES **********************/

    string public m_description;
    string public m_fileUrl;
    bytes32 public m_fileHash;


    uint256 public m_price;
    uint256 public m_cancellationFee;

    uint256 public m_rentDateStart;
    uint256 public m_rentDateEnd;

    uint256 public m_noCancelPeriod;
    uint256 public m_acceptObjectPeriod;

    address public m_client;

    State internal m_state;


    /************************** FALLBACK **********************/

    function() external payable onlyState(State.OFFER) {
        require(msg.value >= m_price);
        require(msg.sender != owner);
        require(m_rentDateStart > getCurrentTime());


        changeState(State.PAID);
        m_client = msg.sender;

        if (msg.value > m_price) {
            msg.sender.transfer(msg.value-m_price);
        }
    }
    /************************** EXTERNAL **********************/


    function rejectPayment() external onlyOwner onlyState(State.PAID) {
        refundWithoutCancellationFee();
    }


    function refund() external onlyClient onlyState(State.PAID) {
        refundWithoutCancellationFee();
    }

    function startRent() external onlyClient onlyState(State.NO_CANCEL) {
        require(getCurrentTime() > m_rentDateStart);

        changeState(State.RENT);
        owner.transfer(address(this).balance);
    }

    function cancelBooking() external onlyState(State.NO_CANCEL) {
        if (getCurrentTime() >= m_rentDateStart+m_acceptObjectPeriod) {
            require(msg.sender == owner);
        } else {
            require(msg.sender == m_client);
        }

        refundWithCancellationFee();
    }

    /************************** PUBLIC **********************/

    function getCurrentState() public view returns(State) {
        if (m_state == State.PAID) {
            if (getCurrentTime() >= m_rentDateStart - m_noCancelPeriod) {
                return State.NO_CANCEL;
            } else {
                return State.PAID;
            }
        } if (m_state == State.RENT)  {
            if (getCurrentTime() >= m_rentDateEnd) {
                return State.FINISHED;
            } else {
                return State.RENT;
            }
        } else {
            return m_state;
        }
    }

    /************************** INTERNAL **********************/


    function changeState(State _newState) internal {
        State currentState = getCurrentState();

        if (State.OFFER == _newState) {
            assert(State.PAID == currentState || State.NO_CANCEL == currentState);

        } else if (State.PAID == _newState) {
            assert(State.OFFER == currentState);
            assert(address(this).balance > 0);

        } else if (State.NO_CANCEL == _newState) {
            assert(false); // no direct change

        } else if (State.CANCELED == _newState) {
            assert(State.NO_CANCEL == currentState);

        } else if (State.RENT == _newState) {
            assert(State.NO_CANCEL == currentState);

        } else if (State.FINISHED == _newState) {
            assert(false); // no direct change

        }

        m_state = _newState;
        emit StateChanged(_newState);
    }

    function getCurrentTime() public view returns (uint256) {
        return now;
    }

    /************************** PRIVATE **********************/

    function refundWithoutCancellationFee() private  {
        address client = m_client;
        m_client = address(0);
        changeState(State.OFFER);


        client.transfer(address(this).balance);
    }

    function refundWithCancellationFee() private {
        address client = m_client;
        m_client = address(0);
        changeState(State.CANCELED);

        owner.transfer(m_cancellationFee);
        client.transfer(address(this).balance);
    }

}