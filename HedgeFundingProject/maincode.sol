//Name:- Shreyansh Dangi
//Email:- shreyanshdangi464@gmail.com
//GitHub Account:- ShreyanshDangi
/*-----------------------------------------------------------------------------------*/


//Let's assume 1 crore = 1wei
/*Here in this HedgeFunding we will not be doing any VOTING beacause its fund mangers responsiblity
to invest anywhere for the profits including the asset as well as non asset class.*/


/*-----------------------------------------------------------------------------------*/

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.8.6 <0.9.0; 

contract hedgeFunding 
{
    mapping(address => uint) public investors; //These are the rich peoples
    address public fundmanager;  //Someone who is SEBI registered and certified Analyst
    uint public minContribution; //Min contribution by one big investor
    uint public deadline; //It is close hedge fund which means there is a time limit to invest in it
    uint public target; //It is the value of starting the fund
    uint public raisedAmount; 
    uint public noOfinvestors;




    mapping(address => uint) public investmenttypes; //This is to trace the types of investment
    uint public backedAmount; //Amount comes from investment after the tenure over with the principal amount
    uint public noOfInvestmentsgivingback; //It is telling that from how many investemtn the money has returned with profit
    address[] public investmenttypeAddresses;




    address[] public investorAddresses;

    constructor(uint _target, uint _deadline) 
    {
        target = _target;
        deadline = block.timestamp + _deadline;
        minContribution = 100 wei;
        fundmanager = msg.sender;
    }

    function sendEth() public payable 
    {
        require(block.timestamp < deadline, "Deadline for investing is OVER...");
        require(msg.value >= minContribution, "Minimum Contribution isn't fulfilled...Try again");

        if (investors[msg.sender] == 0) 
        {
            noOfinvestors++;
            investorAddresses.push(msg.sender);
        }

        investors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns (uint) 
    {
        return address(this).balance; //To get the current balance of the contract
    }

    function refund() public 
    {
        require(block.timestamp > deadline && raisedAmount < target, "You are not eligible for a refund");
        require(investors[msg.sender] > 0, "You have not invested any amount");

        address payable user = payable(msg.sender);
        user.transfer(investors[msg.sender]);
        investors[msg.sender] = 0;
    }

    // Structure to represent investment requests
    struct InvestmentRequest 
    {
        string description; //About the assest in which investing
        address payable recipient; //Address where to park the raised money
        uint value; //Value of money need to invest in the given asset 
        uint percentGainPerYear; //Gain on principle amount Year on Year
        bool completed;
    }

    mapping(uint => InvestmentRequest) public investments; //Mapping the investments with numbers
    uint public numInvestments; //Calculating the number of Investments

    modifier onlyfundmanager() 
    {
        require(msg.sender == fundmanager, "Only the Fund Manager can call this function");
        _;
    }

    function createInvestmentRequest(string memory _description, address payable _recipient, uint _value, uint _percentGainPerYear) public onlyfundmanager 
    {
        InvestmentRequest storage newInvestment = investments[numInvestments];
        numInvestments++;
        newInvestment.description = _description;
        newInvestment.recipient = _recipient;
        newInvestment.value = _value;
        newInvestment.percentGainPerYear = _percentGainPerYear;
        newInvestment.completed = false;
    }

    function makeInvestment(uint _investmentNo) public onlyfundmanager 
    {
        InvestmentRequest storage thisInvestment = investments[_investmentNo];
        require(!thisInvestment.completed, "The investment has already been completed");
        thisInvestment.recipient.transfer(thisInvestment.value);
        thisInvestment.completed = true;
    }

    

    function calculateTotalProfit(uint _years) public view returns (uint totalProfit) 
    {
        require(_years > 0, "Years must be greater than 0");

        for (uint i = 0; i < numInvestments; i++) 
        {
            InvestmentRequest storage investment = investments[i];
            if (investment.completed) 
            {
                uint compoundedValue = investment.value;
                for (uint j = 0; j < _years; j++) 
                {
                    compoundedValue = (compoundedValue * (100 + investment.percentGainPerYear)) / 100;
                }
                totalProfit += compoundedValue - investment.value;
                
            }
        }

        return totalProfit;
    }

    function calculateInvestmentProfit(uint _investmentNo, uint _years) public view returns (uint investmentProfit) {
        require(_years > 0, "Years must be greater than 0");

        InvestmentRequest storage investment = investments[_investmentNo];
        require(investment.completed, "Investment is not completed");

        uint compoundedValue = investment.value;
        for (uint j = 0; j < _years; j++) {
            compoundedValue = (compoundedValue * (100 + investment.percentGainPerYear)) / 100;
        }

        investmentProfit = compoundedValue - investment.value;
        return investmentProfit;
    }

    function sendEthProfitback() public payable //You need to also give the PRINCIPLE AMOUNT back with profit manually after checking the profit from calculateInvestmentProfit()
    {
        if (investmenttypes[msg.sender] == 0) 
        {
            noOfInvestmentsgivingback++;
            investmenttypeAddresses.push(msg.sender);
        }

        investmenttypes[msg.sender] += msg.value;
        backedAmount += msg.value;
    }

    function distributeProfits(uint _years) public payable  onlyfundmanager // This will distrube the money again to the investors with the profits taken from each investment seperately using the help of sendEthProfitback()
    {
        uint totalProfit = calculateTotalProfit(_years);
        require(totalProfit > 0, "No profits available for distribution");

        for (uint i = 0; i < investorAddresses.length; i++) 
        {
            address payable user = payable(investorAddresses[i]);
            uint principalAmount = investors[user];
            uint profitShare = (totalProfit * principalAmount / raisedAmount);
            user.transfer(principalAmount + profitShare);
        }
    }




}
