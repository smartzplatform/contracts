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
 */
contract Registry is Ownable {

    function Registry() public payable {

        //empty element with id=0
        records.push(Record('',0,'',0));

    }

    /************************** STRUCT **********************/

    struct Record {
        string certificateId;
        bytes32 fullName;
        string certificateDocumentUrl;
        bytes32 hashOfCertificateDocument;
    }

    /************************** EVENTS **********************/

    event RecordAdded(uint256 id, string certificateId, bytes32 fullName, string certificateDocumentUrl, bytes32 hashOfCertificateDocument);

    /************************** CONST **********************/

    string public constant name = 'Certificates registry';
    string public constant description = 'Some description';
    string public constant recordName = 'Certificate';

    /************************** PROPERTIES **********************/

    Record[] public records;
    mapping (bytes32 => uint256) certificateId_mapping;
    mapping (bytes32 => uint256) fullName_mapping;
    mapping (bytes32 => uint256) certificateDocumentUrl_mapping;
    mapping (bytes32 => uint256) hashOfCertificateDocument_mapping;

    /************************** EXTERNAL **********************/

    function addRecord(string _certificateId,bytes32 _fullName,string _certificateDocumentUrl,bytes32 _hashOfCertificateDocument) external onlyOwner returns (uint256) {
        require(0==findIdByCertificateId(_certificateId));
        require(0==findIdByFullName(_fullName));
        require(0==findIdByCertificateDocumentUrl(_certificateDocumentUrl));
        require(0==findIdByHashOfCertificateDocument(_hashOfCertificateDocument));


        records.push(Record(_certificateId, _fullName, _certificateDocumentUrl, _hashOfCertificateDocument));

        certificateId_mapping[keccak256(_certificateId)] = records.length-1;
        fullName_mapping[(_fullName)] = records.length-1;
        certificateDocumentUrl_mapping[keccak256(_certificateDocumentUrl)] = records.length-1;
        hashOfCertificateDocument_mapping[(_hashOfCertificateDocument)] = records.length-1;

        RecordAdded(records.length - 1, _certificateId, _fullName, _certificateDocumentUrl, _hashOfCertificateDocument);

        return records.length - 1;
    }

    /************************** PUBLIC **********************/

    function getRecordsCount() public view returns(uint256) {
        return records.length - 1;
    }


    function findByCertificateId(string _certificateId) public view returns (uint256 id, string certificateId, bytes32 fullName, string certificateDocumentUrl, bytes32 hashOfCertificateDocument) {
        Record record = records[ findIdByCertificateId(_certificateId) ];
        return (
            findIdByCertificateId(_certificateId),
            record.certificateId, record.fullName, record.certificateDocumentUrl, record.hashOfCertificateDocument
        );
    }

    function findIdByCertificateId(string certificateId) internal view returns (uint256) {
        return certificateId_mapping[keccak256(certificateId)];
    }


    function findByFullName(bytes32 _fullName) public view returns (uint256 id, string certificateId, bytes32 fullName, string certificateDocumentUrl, bytes32 hashOfCertificateDocument) {
        Record record = records[ findIdByFullName(_fullName) ];
        return (
            findIdByFullName(_fullName),
            record.certificateId, record.fullName, record.certificateDocumentUrl, record.hashOfCertificateDocument
        );
    }

    function findIdByFullName(bytes32 fullName) internal view returns (uint256) {
        return fullName_mapping[(fullName)];
    }


    function findByCertificateDocumentUrl(string _certificateDocumentUrl) public view returns (uint256 id, string certificateId, bytes32 fullName, string certificateDocumentUrl, bytes32 hashOfCertificateDocument) {
        Record record = records[ findIdByCertificateDocumentUrl(_certificateDocumentUrl) ];
        return (
            findIdByCertificateDocumentUrl(_certificateDocumentUrl),
            record.certificateId, record.fullName, record.certificateDocumentUrl, record.hashOfCertificateDocument
        );
    }

    function findIdByCertificateDocumentUrl(string certificateDocumentUrl) internal view returns (uint256) {
        return certificateDocumentUrl_mapping[keccak256(certificateDocumentUrl)];
    }


    function findByHashOfCertificateDocument(bytes32 _hashOfCertificateDocument) public view returns (uint256 id, string certificateId, bytes32 fullName, string certificateDocumentUrl, bytes32 hashOfCertificateDocument) {
        Record record = records[ findIdByHashOfCertificateDocument(_hashOfCertificateDocument) ];
        return (
            findIdByHashOfCertificateDocument(_hashOfCertificateDocument),
            record.certificateId, record.fullName, record.certificateDocumentUrl, record.hashOfCertificateDocument
        );
    }

    function findIdByHashOfCertificateDocument(bytes32 hashOfCertificateDocument) internal view returns (uint256) {
        return hashOfCertificateDocument_mapping[(hashOfCertificateDocument)];
    }
}
