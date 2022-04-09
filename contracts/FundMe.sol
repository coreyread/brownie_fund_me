// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// For whatever reason the remapping for @chainlink doesn't work properly so we're using the direct path here
// This may have been because my brownie-config file was named with an _
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // Checks for overflows
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; //sender is the address that deploys the contract
    }

    function getSender() public view returns (address) {
        return owner;
    }

    // payable marks a function as something that gets payment (these are red)
    // msg stores info on transactions
    // revert undoes transactions
    function fund() public payable {
        //uint256 minimumUSD = 1 * 10e18;

        //require(minimumUSD <= getConversionRate(msg.value), "You need to spend more ETH!");

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10e10);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10e18;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    // modifer lets you write your own requirements that can be added to other functions
    //_; means run the rest of the function code.  This can also be placed before the requirement
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // transfer sends money to the sender
    // this invokes this contract, with .balance being all of the funds at that address (in the contract in this case)
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
