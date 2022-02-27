//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "../libraries/StringUtils.sol";
import {Base64} from "../libraries/Base64.sol";


/// @title Contract to deploy customizable domains to Polygon network
/// @author Siddharth Badyal
/// @notice Contract can be used to implement a simple NFT-based domain name service
/// @dev All functions currently in active dev 
contract CoolDomains is ERC721URIStorage {

    using Counters for Counters.Counter;
    string public tld;

    Counters.Counter private _tokenId;

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5a"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    mapping (string => address) public domains;
    mapping (string => string) public records;

    //Constructor to Initialize smart contract for a specified Top-level domain
    constructor (string memory _tld) payable ERC721("Cool Name Service","CNS"){
        tld = _tld;
        console.log("%s Name Service deployed!",_tld);
    }

    //reusable custom modifier for functions that must only be run by the domain owner
    modifier domainOwner(string calldata name) {
        require(domains[name]==msg.sender, "Whoops! Hey Naughty, you're not the owner");
        _;
    }

    // This function will give us the price of a domain based on length
    function price(string calldata name) public pure returns(uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);
        
        if (len == 3) {
            return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    function register(string calldata name) public payable{
        require(domains[name]==address(0));

        uint _price = price(name);

        //Check if enough fee is supplied for the tx
        require(msg.value >= _price, "That's not very cash money of you. More Matic required!");
        
        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name,".",tld));
        
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(abi.encodePacked(svgPartOne,_name,svgPartTwo));

        uint256 recordId = _tokenId.current();
  	    uint256 length = StringUtils.strlen(name);
		string memory strLen = Strings.toString(length);

        console.log("Registering %s.%s on the contract with tokenID %d", name, tld, recordId);

		// Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
        bytes(
            string(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the Ninja name service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
                )
              )
            )
        );

        string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

		console.log("\n--------------------------------------------------------");
	    console.log("Final tokenURI", finalTokenUri);
	    console.log("--------------------------------------------------------\n");

        _safeMint(msg.sender, recordId);
        _setTokenURI(recordId, finalTokenUri);
        domains[name] = msg.sender;

        _tokenId.increment();


    }

    function getAddress(string calldata name) public view returns(address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public domainOwner(name) {
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns(string memory) {
        return records[name];
    }


}

