//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.1;

contract MLM {
    address public ownerWallet;
    uint256 public totalUsers;
    uint256 public rewardWallet;
    uint256 public levelRewardWallet;
    uint256 public distributionWallet;
    uint256 public totalAmountDistributed;
    address[] public levelWinners;
    
    struct User {
        uint256 id;
        address inviter;
        uint256 totalReferals;
        uint256 totalWins;
        uint256 totalRecycles;
        uint256 levelsPurchased;
        uint256 upline;
        address[] uplines;
        address[] referral;
        bool isExist;
        uint256 loss;
        bool getLevelReward;
    }
 
    struct UserIncomes{
        uint256 directIncome;
        uint256 rewardIncome;
        uint256 levelIncome;
        uint256 recycleIncome;
        uint256 upgradeIncome;
        uint256 levelRewardIncome;
    }
 
    struct UserFunds{
        uint256 recycleFund;
        uint256 levelFund;
    }


    uint256[] public levels;
   
    mapping(address => User) public users;
    mapping(address => UserIncomes) public usersIncomes;
    mapping(address => UserFunds) public usersFund;
    // mapping(address => UserLevels) public userLevels;

    mapping(uint256 => address) public users_ids;
    
    event Register(address indexed addr, address indexed inviter, uint256 id);
    event BuyLevel(
        address indexed addr,
        address indexed upline,
        uint8 level
    );
    event buyLevelEvent(address indexed _user, uint256 _level);

    constructor() public{
        totalUsers = 0;
        ownerWallet = msg.sender;
        levels.push(0.05 ether);
        levels.push(0.01 ether);
        levels.push(0.02 ether);
        levels.push(0.03 ether);
        levels.push(0.04 ether);
        levels.push(0.05 ether);
        levels.push(0.06 ether);
        levels.push(0.07 ether);
        levels.push(0.08 ether);
        levels.push(0.09 ether);
        levels.push(0.10 ether);
        newUser(msg.sender, address(0));
        users[msg.sender].levelsPurchased = 10;
        users[msg.sender].referral= new address[](0);
        users[msg.sender].upline = 0;
        users[msg.sender].uplines = new address[](0);
    }

    function newUser(address _addr, address _inviter) private {
        totalUsers++;
        users[_addr].id = totalUsers;
        users[_addr].inviter = _inviter;
        users_ids[totalUsers] = _addr;
        users[_addr].isExist = true;
        users[_addr].getLevelReward = false;
        users[msg.sender].levelsPurchased = 0;
        emit Register(_addr, _inviter, totalUsers);

    }

    function _register(
        address _user,
        address _inviter,
        uint256 _value
    ) private {
        require(users[_user].id == 0, "User arleady registered");
        require(users[_inviter].id != 0, "Inviter not registered");
        require(_value >= levels[0], "Insufficient funds");

        
        rewardWallet += (levels[0] * 10) / 100;
        levelRewardWallet += (levels[0] * 10) / 100;

        uint256 referalMoney = (levels[0] * 80) / 100;
        usersIncomes[_inviter].directIncome += (referalMoney - (referalMoney * 20) / 100);
        usersFund[_inviter].recycleFund += (referalMoney * 10) / 100;
        usersFund[_inviter].levelFund += (referalMoney * 10) / 100;
         users[_inviter].totalReferals++;
        // setUplines(users[_inviter].id);
        // setUplines(users[msg.sender].id);
        // if(usersIncomes[_inviter].recycleFund>=levels[0])
        // recycleId(_inviter);
        
        // if((usersIncomes[_inviter].levelFund>=levels[users[_inviter].levelsPurchased+1]) && users[_inviter].levelsPurchased < 10)
        // autoBuyLevel(_inviter);
        
        address(uint256(_inviter)).transfer(referalMoney - (referalMoney * 20) / 100);

        totalAmountDistributed += (referalMoney - (referalMoney * 20) / 100);
        
        newUser(_user, _inviter);
    }

    function register(uint256  _inviter_id) external payable {
        // uint256 tempReferrerID = _inviter_id;
        _register(msg.sender, users_ids[_inviter_id], msg.value);
        address add;
        uint256 id = _inviter_id;
        if(users[users_ids[_inviter_id]].referral.length >= 4) {
            add = findFreeReferrer(users_ids[_inviter_id]);
            id = users[add].id;
        }
        
            // if( users[users_ids[id]].referral.length==4){
            //     levelWinners.push(users_ids[id]);
            // }
        
        users[users_ids[id]].referral.push(msg.sender);
        users[msg.sender].upline =id;
       
    }

    function buyLevel(uint256 _level) public payable {
        require( _level > users[msg.sender].levelsPurchased,"Already purchased level" );
        require(users[msg.sender].isExist, "User not exist");
        require(_level > 0 && _level <= 10, "Incorrect level");
        require(msg.value == levels[_level], "Incorrect Value");
        require( users[msg.sender].levelsPurchased == _level - 1,"You haven't purchased previous level yet");
      
        uint256 upgradeAmount = (levels[_level] * 20) / 100;
        address _inviter = users[msg.sender].inviter;
        usersIncomes[_inviter].levelIncome += (upgradeAmount -(20 * upgradeAmount) / 100);
        usersFund[_inviter].recycleFund +=(10 * upgradeAmount) /100;
        usersFund[_inviter].levelFund += (10 * upgradeAmount) / 100;
        // if(usersIncomes[_inviter].recycleFund>=levels[0])
        // recycleId(_inviter);
        
        // if((usersIncomes[_inviter].levelFund>=levels[users[_inviter].levelsPurchased+1]) && users[_inviter].levelsPurchased < 10)
        // autoBuyLevel(_inviter);

        address(uint256(users[msg.sender].inviter)).transfer(
            upgradeAmount - (20 * upgradeAmount) / 100
        );

        totalAmountDistributed += (upgradeAmount - (20 * upgradeAmount) / 100);

        if (users[msg.sender].levelsPurchased + 1 < 10)
            users[msg.sender].levelsPurchased += 1;

        distributeLevelUpgradeAmount(_level, msg.sender);
       
        emit buyLevelEvent(msg.sender, _level);
    }

    function autoBuyLevel(address _user) public {

        uint256 _level = users[_user].levelsPurchased + 1;
        require(_level > 0 && _level <= 10, "Incorrect level");
        require( usersFund[_user].levelFund >= levels[_level],"Incorrect Value");
     
        uint256 upgradeAmount = (levels[_level] * 20) / 100;
        address _inviter= users[_user].inviter;
        usersIncomes[_inviter].levelIncome += (upgradeAmount -(20 * upgradeAmount) /100);
        usersFund[_inviter].recycleFund +=(10 * upgradeAmount) /100;
        usersFund[_inviter].levelFund +=(10 * upgradeAmount) /100;
        
        // if(usersIncomes[_inviter].recycleFund>=levels[0])
        // recycleId(_inviter);
        
        // if((usersIncomes[_inviter].levelFund>=levels[users[_inviter].levelsPurchased+1]) && users[_inviter].levelsPurchased < 10)
        // autoBuyLevel(_inviter);

        address(uint256(users[_user].inviter)).transfer(
            (upgradeAmount - (20 * upgradeAmount) / 100)
        );

        totalAmountDistributed += (upgradeAmount - (20 * upgradeAmount) / 100);
        usersFund[_user].levelFund -= levels[_level];
        users[_user].levelsPurchased += 1;

         //level distribution is done
        distributeLevelUpgradeAmount(_level,_user);

        emit buyLevelEvent(_user, _level);
    }

    function recycleId(address _user) public {
        if(usersFund[_user].recycleFund >= levels[0]){
            usersFund[_user].recycleFund -= levels[0];
            users[_user].totalRecycles+=1;

            uint256 referalMoney = (levels[0] * 80) / 100;

            address _inviter = users[_user].inviter;
            usersIncomes[_inviter].recycleIncome += (referalMoney -(referalMoney * 20) /100);
            usersFund[_inviter].recycleFund += (referalMoney * 10) / 100;
            usersFund[_inviter].levelFund += (referalMoney * 10) / 100;

            address(uint256(_inviter)).transfer(referalMoney - (referalMoney * 20) / 100);
            totalAmountDistributed += (referalMoney -(referalMoney * 20) /100);

            rewardWallet += (levels[0] * 10) / 100;
            levelRewardWallet += (levels[0] * 10) / 100;
            
            // if(usersIncomes[_inviter].recycleFund>=levels[0])
            // recycleId(_inviter);
        
            // if((usersIncomes[_inviter].levelFund>=levels[users[_inviter].levelsPurchased+1]) && users[_inviter].levelsPurchased < 10)
            // autoBuyLevel(_inviter);
        }
    }

    function distributeReward(
        uint256 _winner1,
        uint256 _winner2,
        uint256 _winner3
    ) public {
     
        uint256 first = (50 * rewardWallet) / 100;
        uint256 second = (30 * rewardWallet) / 100;
        uint256 third = (20 * rewardWallet) / 100;

        usersIncomes[users_ids[_winner1]].rewardIncome += (first - (20 * first) / 100);
        usersIncomes[users_ids[_winner2]].rewardIncome += (second - (20 * second) / 100);
        usersIncomes[users_ids[_winner3]].rewardIncome += (third - (20 * third) / 100);

        address(uint256(users_ids[_winner1])).transfer(usersIncomes[users_ids[_winner1]].rewardIncome);
        address(uint256(users_ids[_winner2])).transfer(usersIncomes[users_ids[_winner2]].rewardIncome);
        address(uint256(users_ids[_winner3])).transfer(usersIncomes[users_ids[_winner3]].rewardIncome);

        users[users_ids[_winner1]].totalWins += 1;
        users[users_ids[_winner2]].totalWins += 1;
        users[users_ids[_winner3]].totalWins += 1;

        totalAmountDistributed += (usersIncomes[users_ids[_winner1]].rewardIncome + 
        usersIncomes[users_ids[_winner2]].rewardIncome + usersIncomes[users_ids[_winner3]].rewardIncome);

        rewardWallet = 0;
        
        address _inviter1 = users[users_ids[_winner1]].inviter;
        address _inviter2 = users[users_ids[_winner2]].inviter;
        address _inviter3 = users[users_ids[_winner3]].inviter;
        
        usersFund[_inviter1].recycleFund += (10 * first) / 100;
        usersFund[_inviter2].recycleFund += (10 * second) / 100;
        usersFund[_inviter3].recycleFund += (10 * third) / 100;

        usersFund[_inviter1].levelFund += (10 * first) / 100;
        usersFund[_inviter2].levelFund += (10 * second) / 100;
        usersFund[_inviter3].levelFund += (10 * third) / 100;

        // if(usersIncomes[_inviter1].recycleFund>=levels[0])
        // recycleId(_inviter2);
        
        // if((usersIncomes[_inviter1].levelFund >= levels[users[_inviter1].levelsPurchased+1]) && (users[_inviter1].levelsPurchased < 10))
        // autoBuyLevel(_inviter1);

        // if(usersIncomes[_inviter2].recycleFund>=levels[0])
        // recycleId(_inviter2);
        
        // if((usersFund[_inviter2].levelFund >= levels[users[_inviter2].levelsPurchased+1]) && (users[_inviter2].levelsPurchased < 10))
        // autoBuyLevel(_inviter2);

        // if(usersIncomes[_inviter3].recycleFund>=levels[0])
        // recycleId(_inviter3);
        
        // if((usersFund[_inviter3].levelFund >= levels[users[_inviter3].levelsPurchased+1]) && (users[_inviter3].levelsPurchased < 10))
        // autoBuyLevel(_inviter3);

    }


    function distributeLevelReward() public{
        uint256 size = setLevelWinners();
        uint256 totalprice = levelRewardWallet/size;
        uint256 price = totalprice - (20*totalprice)/100;
        uint256 recyclePrice = (10*totalprice)/100;
        uint256 levelPrice = (10*totalprice)/100;
        for(uint256 i=0;i<levelWinners.length;i++){
            if(levelWinners[i]==address(0)){
                distributionWallet += price;
            }
            address(uint256(levelWinners[i])).transfer(price);
            usersIncomes[levelWinners[i]].levelRewardIncome += price;
            address _inviter = users[levelWinners[i]].inviter;
            
            usersFund[_inviter].recycleFund += recyclePrice;
            usersFund[_inviter].levelFund += levelPrice;
            
            // if(usersIncomes[_inviter].recycleFund>=levels[0])
            // recycleId(_inviter);
            
            // if((usersIncomes[_inviter].levelFund >= levels[users[_inviter].levelsPurchased+1]) && (users[_inviter].levelsPurchased < 10))
            // autoBuyLevel(_inviter);
        }
        totalAmountDistributed += price*levelWinners.length;
    }

    function distributeLevelUpgradeAmount(uint256 _level, address _user) public{
        uint256 x = (levels[_level]*8)/100;
        uint256 y = (20*x)/100;
        uint256 price = (x-y);
        setUplines(users[_user].id);
        address[] memory uplines = new address[](10);
        uplines = users[_user].uplines;
        for(uint256 i=0;i<10;i++){
            if(uplines[i]==address(0))
            {
                //some changes needed
                distributionWallet += price; 
                break;
            }
            else if(users[uplines[i]].levelsPurchased>=(i+1)){
                usersIncomes[uplines[i]].upgradeIncome += price;

                usersFund[uplines[i]].recycleFund += (10*x)/100;
                usersFund[uplines[i]].levelFund += (10*x)/100;
                
                // if(usersIncomes[users_ids[uplines[i]]].recycleFund>=levels[0])
                // recycleId(users[users_ids[uplines[i]]].inviter);
                
                // if((usersIncomes[users_ids[user.upline]].levelFund >= levels[users[users_ids[user.upline]].levelsPurchased+1]) && (users[users_ids[user.uplines[i]]].levelsPurchased < 10))
                // autoBuyLevel(users[users_ids[user.uplines[i]]].inviter);
                
                address(uint256(uplines[i])).transfer(price);
                totalAmountDistributed += price;
                
            }

            else{
                users[uplines[i]].loss += price;
                distributionWallet += price; 
            }
           
        }
    }
    
    function getTotalAmountWithdrawn() public view returns (uint256) {
        return totalAmountDistributed;
    }

    function getTotalUsers() public view returns (uint256) {
        return totalUsers;
    }

    function getRewardWallet()public view returns (uint256) {
        return rewardWallet;
    }
    function getLevelRewardWallet() public view returns (uint256) {
        return levelRewardWallet;
    }

    function getDirectIncome(address _add) public view returns (uint256){
        return usersIncomes[_add].directIncome;
    }

   function getUserInfo(uint256 _id)
        public
        view
        returns (
        address inviter,
        uint256 totalReferals,
        uint256 totalRecycles,
        uint256 totalWins,
        uint256 levelsPurchased,
        uint256 loss
        )
    {
        User memory user = users[users_ids[_id]];
        return (
            user.inviter,
            user.totalReferals,
            user.totalRecycles,
            user.totalWins,
            user.levelsPurchased,
            user.loss
        );
    }
    
    function getUsersIncomes(uint256 _id) public view returns (
        uint256 directIncome,
        uint256 rewardIncome,
        uint256 levelIncome,
        uint256 recycleIncome,
        uint256 upgradeIncome,
        uint256 levelRewardIncome
        )
        {
        return (
            usersIncomes[users_ids[_id]].directIncome,
            usersIncomes[users_ids[_id]].rewardIncome,
            usersIncomes[users_ids[_id]].levelIncome,
            usersIncomes[users_ids[_id]].recycleIncome,
            usersIncomes[users_ids[_id]].upgradeIncome,
            usersIncomes[users_ids[_id]].levelRewardIncome
            );
    }

    function getUsersFunds(uint256 _id) public view returns(
        uint256 recycleFund,
        uint256 levelFund
    ){
        return (
            usersFund[users_ids[_id]].recycleFund,
            usersFund[users_ids[_id]].levelFund
        );
    }
    function withDrawlevelFund() public {
        require(users[msg.sender].levelsPurchased >= 10, "you cannot withdraw amount");

        address(uint256(msg.sender)).transfer(
            usersFund[msg.sender].levelFund
        );

        usersFund[msg.sender].levelFund = 0;
    }
   
    function withdrawDistributionWallet() public{
        require(msg.sender == ownerWallet,"you are not owner");
        address(uint256(ownerWallet)).transfer(distributionWallet);
        totalAmountDistributed += distributionWallet;
        distributionWallet = 0;
    }
    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < 4) return _user;

        address[] memory referrals = new address[](30000);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        referrals[3] = users[_user].referral[3];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint256 i = 0; i < 30000; i++) {
            if(users[referrals[i]].referral.length == 4) {
                    referrals[(i+1)*4] = users[referrals[i]].referral[0];
                    referrals[(i+1)*4+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*4+2] = users[referrals[i]].referral[2];
                    referrals[(i+1)*4+3] = users[referrals[i]].referral[3];
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    
    function setUplines(uint256 _id) public{
        address[] memory uplinesLocal=new address[](10);
        uint256 userId = users[users_ids[_id]].upline;
        for(uint256 i=0;i<10;i++){
            if(userId == 0)
            break;
            uplinesLocal[i]=users_ids[userId];
            userId = users[users_ids[userId]].upline;
        }
        users[users_ids[_id]].uplines = uplinesLocal;
       
    }

    function getUplines(uint256 _id) public view returns(address[] memory){
        return users[users_ids[_id]].uplines;
    }

    function setLevelWinners() public returns(uint256){
        address[] memory levelWinner = new address[](100);
        uint256 i;
        uint256 j=0;
        for(i=1;i<=totalUsers;i++){
             if(users[users_ids[i]].referral.length==4){
                levelWinner[j++]= (users_ids[i]);
            }
        }
        levelWinners = levelWinner;
        return j;
    }

    function getLevelWinners() public view returns(address[] memory){
     return levelWinners;
    }
}
