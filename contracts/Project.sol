//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Project{

   // Project state
    enum State {
        Fundraising,
        Expired,
        Successful
    }

    // Structs
    struct WithdrawRequest{
        string description;
        uint256 amount;
        uint256 noOfVotes;
        mapping(address => bool) voters;
        bool isCompleted;
        address payable reciptent;
    }

    // Variables
    address payable masterContract;
    address payable admin;
    address payable public developer = payable(0xDD89A7C8902Ce8fEff3A318F088A5b31934f6317);
    uint256 public royaltyGraceExpiry = 12345678; // when my entitlement to a share of the royalty ends
    address payable public creator;
    uint256 public minimumContribution;
    uint256 public deadline;
    uint256 public targetContribution; // required to reach at least this much amount
    uint public completeAt;
    uint256 public raisedAmount; // Total raised amount till now
    uint256 public noOfContributers;
    string public projectTitle;
    string public projectDes;
    State public state = State.Fundraising; 
    bool public isRevealed = false;
    bool public isVerified = false;

    mapping (address => uint) public contributiors;
    mapping (uint256 => WithdrawRequest) public withdrawRequests;

    uint256 public numOfWithdrawRequests = 0;


    // Modifiers

    modifier isMasterContract() {
        require(msg.sender == masterContract, 'You do not have the master rights to perform this operation!');
        _;
    }

    modifier isProjectVerified(){
        require(isVerified == true, 'Project must be verified');
        _;
    }

    modifier isAdmin(){
        require(msg.sender == admin,'You dont have admin access to perform this operation !');
        _;
    }

    modifier isCreator(){
        require(msg.sender == creator,'You dont have creator access to perform this operation !');
        _;
    }

    modifier isOriginalSenderCreator(address senderAddress){
        require(senderAddress == creator,'Original sender is not creator and cannot perform this operation !');
        _;
    }

    modifier validateExpiry(State _state){
        require(state == _state,'Invalid state');
        require(block.timestamp < deadline,'Deadline has passed !');
        _;
    }

    // Events

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint amount, uint currentTotal);
    // Event that will be emitted whenever withdraw request created
    event WithdrawRequestCreated(
        uint256 requestId,
        string description,
        uint256 amount,
        uint256 noOfVotes,
        bool isCompleted,
        address reciptent
    );
    // Event that will be emitted whenever contributor vote for withdraw request
    event WithdrawVote(address voter, uint totalVote);
    // Event that will be emitted whenever contributor vote for withdraw request
    event AmountWithdrawSuccessful(
        uint256 requestId,
        string description,
        uint256 amount,
        uint256 noOfVotes,
        bool isCompleted,
        address reciptent
    );


    // @dev Create project
    // @return null

   constructor(
       address _owner,
       address _creator,
       address _masterContract,
       uint256 _minimumContribution,
       uint256 _deadline,
       uint256 _targetContribution,
       string memory _projectTitle,
       string memory _projectDes
   ) {
        admin = payable(_owner);
        creator = payable(_creator);
        masterContract = payable(_masterContract);
        minimumContribution = _minimumContribution;
        deadline = _deadline;
        targetContribution = _targetContribution;
        projectTitle = _projectTitle;
        projectDes = _projectDes;
        raisedAmount = 0;
   }

    function setRoyaltyGracePeriod (uint256 unixTs) external isAdmin() {
        royaltyGraceExpiry = unixTs;
    }

    function setVisibility (bool isVisible) external isAdmin() {
        isRevealed = isVisible;
    }

    function setVerification (bool verified) external isAdmin() {
        isVerified = verified;
    }

    // @dev Anyone can contribute one of the stables USDT, USDC, BUSD, DAI by passing it into the function parameter
    // @return null
    function contribute(address _contributor, uint256 amount, IERC20 tokenAddress) public isProjectVerified() isMasterContract() {
        if(contributiors[_contributor] == 0){
            noOfContributers++;
        }

        contributiors[_contributor] += amount;
        raisedAmount += amount;
        //Call this from the client to first approve this contract to send tokens on behalf of the user to itself
        // tokenAddress.approve(address(this), amount);
        require(tokenAddress.allowance(msg.sender, address(this)) >= amount);
        tokenAddress.transferFrom(msg.sender, address(this), amount);
        emit FundingReceived(_contributor, amount, raisedAmount);
        checkFundingCompleteOrExpire();
    }

    // @dev complete or expire funding
    // @return null

    function checkFundingCompleteOrExpire() internal {
        if(raisedAmount >= targetContribution){
            state = State.Successful; 
        }else if(block.timestamp > deadline){
            state = State.Expired; 
        }
        completeAt = block.timestamp;
    }

    // @dev Get contract current balance
    // @return uint 

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    // @dev Request refunt if funding expired
    // @return boolean

    function requestRefund() public validateExpiry(State.Expired) returns(bool) {
        require(contributiors[msg.sender] > 0,'You dont have any contributed amount !');
        address payable user = payable(msg.sender);
        user.transfer(contributiors[msg.sender]);
        contributiors[msg.sender] = 0;
        return true;
    }

    // @dev Request contributor for withdraw amount
    // @return null
    function createWithdrawRequest(string memory _description,uint256 _amount,address payable _reciptent) public isCreator() validateExpiry(State.Successful) {
        WithdrawRequest storage newRequest = withdrawRequests[numOfWithdrawRequests];
        numOfWithdrawRequests++;

        newRequest.description = _description;
        newRequest.amount = _amount;
        newRequest.noOfVotes = 0;
        newRequest.isCompleted = false;
        newRequest.reciptent = _reciptent;

        emit WithdrawRequestCreated(numOfWithdrawRequests, _description, _amount, 0, false, _reciptent );
    }

    // @dev contributors can vote for withdraw request
    // @return null

    function voteWithdrawRequest(uint256 _requestId) public {
        require(contributiors[msg.sender] > 0,'Only contributor can vote !');
        WithdrawRequest storage requestDetails = withdrawRequests[_requestId];
        require(requestDetails.voters[msg.sender] == false,'You already voted !');
        requestDetails.voters[msg.sender] = true;
        requestDetails.noOfVotes += 1;
        emit WithdrawVote(msg.sender,requestDetails.noOfVotes);
    }


    // @dev Owner can withdraw requested amount
    // @return null

    function withdrawRequestedAmount(uint256 _requestId, IERC20 tokenToWithdraw) isCreator() validateExpiry(State.Successful) isMasterContract() external {
        WithdrawRequest storage requestDetails = withdrawRequests[_requestId];
        require(requestDetails.isCompleted == false, 'Request already completed');
        require(requestDetails.noOfVotes >= noOfContributers/5, 'At least 20% contributor need to vote for this request');
        require(requestDetails.amount <= tokenToWithdraw.balanceOf(address(this)), 'Project contract does not have enough balance to disburse');

        tokenToWithdraw.transferFrom(address(this), requestDetails.reciptent, requestDetails.amount/50 * 49);

        if(block.timestamp <= royaltyGraceExpiry) {
            tokenToWithdraw.transferFrom(address(this), admin, requestDetails.amount/100);
            tokenToWithdraw.transferFrom(address(this), developer, requestDetails.amount/100);  
        } else {
            tokenToWithdraw.transferFrom(address(this), admin, requestDetails.amount/50);
        }
        requestDetails.isCompleted = true;

        emit AmountWithdrawSuccessful(
            _requestId,
            requestDetails.description,
            requestDetails.amount,
            requestDetails.noOfVotes,
            true,
            requestDetails.reciptent
        );

    }

    // @dev Get contract details
    // @return all the project's details

    function getProjectDetails() public view returns(
        address payable projectStarter,
        uint256 minContribution,
        uint256  projectDeadline,
        uint256 goalAmount, 
        uint completedTime,
        uint256 currentAmount, 
        string memory title,
        string memory desc,
        State currentState,
        uint256 balance
    ){
        projectStarter=creator;
        minContribution=minimumContribution;
        projectDeadline=deadline;
        goalAmount=targetContribution;
        completedTime=completeAt;
        currentAmount=raisedAmount;
        title=projectTitle;
        desc=projectDes;
        currentState=state;
        balance=address(this).balance;
    }

}