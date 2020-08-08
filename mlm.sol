//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.1;


contract MLM {
    address internal ownerWallet;
    uint256 internal totalUsers;
    uint256 internal rewardWallet;
    uint256 internal levelRewardWallet;
    uint256 internal distributionWallet;
    uint256 internal totalAmountDistributed;
    struct User {
        uint256 id;
        address inviter;
        uint256 totalReferals;
        uint256 totalRecycles;
        uint256 dailyReferrals;
        uint256 levelsPurchased;
        address[] referral;
        bool isExist;
    }
 
 struct UserIncomes{
        uint256 directIncome;
        uint256 rewardIncome;
        uint256 levelIncome;
        uint256 recycleIncome;
        uint256 recycleFund;
        uint256 levelFund;
 }
 

    uint256[] internal levels;
   
    mapping(address => User) internal users;
    mapping(address => UserIncomes) internal usersIncomes;
    mapping(uint256 => address) internal users_ids;
    
    event Register(address indexed addr, address indexed inviter, uint256 id);
    event BuyLevel(
        address indexed addr,
        address indexed upline,
        uint8 level
    );
    event buyLevelEvent(address indexed _user, uint256 _level);

    constructor() public {
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
    }

    function newUser(address _addr, address _inviter) private {
        totalUsers++;
        users[_addr].id = totalUsers;
        users[_addr].inviter = _inviter;
        users_ids[totalUsers] = _addr;
        
        //level logic pending
    

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
        UserIncomes memory inviter = usersIncomes[_inviter];
        UserIncomes memory incomes;
        
        incomes = UserIncomes({
            directIncome : inviter.directIncome+(referalMoney - (referalMoney * 20) / 100),
            recycleFund : inviter.recycleFund+(referalMoney * 10) / 100,
            levelFund : inviter.levelFund+(referalMoney * 10) / 100,
            rewardIncome: inviter.rewardIncome,
            levelIncome: inviter.levelIncome,
            recycleIncome: inviter.recycleIncome
       
        });
        usersIncomes[_inviter] = incomes;
        
        users[_inviter].dailyReferrals++;
        address(uint256(_inviter)).transfer(referalMoney - (referalMoney * 20) / 100);

        totalAmountDistributed += (referalMoney - (referalMoney * 20) / 100);
        
        newUser(_user, _inviter);
    }

    function register(uint256  _inviter_id) external payable {
        uint256 tempReferrerID = _inviter_id;
        _register(msg.sender, users_ids[_inviter_id], msg.value);
        address add;
        uint256 id = _inviter_id;
        if(users[users_ids[_inviter_id]].referral.length >= 4) {
            add = findFreeReferrer(users_ids[_inviter_id]);
            id = users[add].id;
        }
        users[users_ids[id]].referral.push(msg.sender);
        users[users_ids[tempReferrerID]].totalReferals++;
    }

    function buyLevel(uint256 _level) public payable {
        require( _level > users[msg.sender].levelsPurchased,"Already purchased level" );
        require(users[msg.sender].isExist, "User not exist");
        require(_level > 0 && _level <= 10, "Incorrect level");
        require(msg.value == levels[_level], "Incorrect Value");
        require( users[msg.sender].levelsPurchased == _level - 1,"You haven't purchased previous level yet");
      
        uint256 upgradeAmount = (levels[_level] * 20) / 100;
        usersIncomes[users[msg.sender].inviter].levelIncome += (upgradeAmount -(20 * upgradeAmount) / 100);
        usersIncomes[users[msg.sender].inviter].recycleFund +=(10 * upgradeAmount) /100;
        usersIncomes[users[msg.sender].inviter].levelFund += (10 * upgradeAmount) / 100;

        address(uint256(users[msg.sender].inviter)).transfer(
            upgradeAmount - (20 * upgradeAmount) / 100
        );

        totalAmountDistributed += (upgradeAmount - (20 * upgradeAmount) / 100);

        // address(uint256(users[msg.sender].inviter)).transfer((levels[_level]*20)/100);
        if (users[msg.sender].levelsPurchased + 1 < 10)
            users[msg.sender].levelsPurchased += 1;

        //80% distribution isleft
        distributionWallet += (levels[_level] * 80) / 100;

          //level distribution is pending

        emit buyLevelEvent(msg.sender, _level);
    }

    function autoBuyLevel() internal {

        uint256 _level = users[msg.sender].levelsPurchased + 1;
        
        require(users[msg.sender].isExist, "User not exist");
        require(_level > 0 && _level <= 10, "Incorrect level");
        require( usersIncomes[msg.sender].levelFund >= levels[_level],"Incorrect Value");
     
        uint256 upgradeAmount = (levels[_level] * 20) / 100;
        usersIncomes[users[msg.sender].inviter].levelIncome += (upgradeAmount -(20 * upgradeAmount) /100);
        usersIncomes[users[msg.sender].inviter].recycleFund +=(10 * upgradeAmount) /100;
        usersIncomes[users[msg.sender].inviter].levelFund +=(10 * upgradeAmount) /100;

        address(uint256(users[msg.sender].inviter)).transfer(
            (upgradeAmount - (20 * upgradeAmount) / 100)
        );

        totalAmountDistributed += (upgradeAmount - (20 * upgradeAmount) / 100);
        usersIncomes[msg.sender].levelFund -= levels[_level];
        users[msg.sender].levelsPurchased += 1;

        //80% distribution is left
        distributionWallet += (levels[_level] * 80) / 100;

        //level distribution is pending

        emit buyLevelEvent(msg.sender, _level);
    }

    function recycleId() internal {
        for (uint256 i = 1; i <= totalUsers; i++) {
            if (usersIncomes[users_ids[i]].recycleFund >= levels[0]) {
                usersIncomes[users_ids[i]].recycleFund -= levels[0];
                users[users_ids[i]].totalRecycles+=1;

                rewardWallet += (levels[0] * 10) / 100;
                levelRewardWallet += (levels[0] * 10) / 100;

                uint256 referalMoney = (levels[0] * 80) / 100;

                address _inviter = users[users_ids[i]].inviter;
                usersIncomes[_inviter].recycleIncome += (referalMoney -(referalMoney * 20) /100);
                usersIncomes[_inviter].recycleFund += (referalMoney * 10) / 100;
                usersIncomes[_inviter].levelFund += (referalMoney * 10) / 100;

                address(uint256(_inviter)).transfer(
                    referalMoney - (referalMoney * 20) / 100
                );

                totalAmountDistributed += (referalMoney -(referalMoney * 20) /100);

                rewardWallet += (referalMoney * 10) / 100;
                levelRewardWallet += (referalMoney * 10) / 100;
            }
        }
    }

    function distributeReward(
        address _winner1,
        address _winner2,
        address _winner3
    ) internal {
     
        uint256 first = (50 * rewardWallet) / 100;
        uint256 second = (30 * rewardWallet) / 100;
        uint256 third = (20 * rewardWallet) / 100;

        usersIncomes[_winner1].rewardIncome += (first - (20 * first) / 100);
        usersIncomes[_winner2].rewardIncome += (second - (20 * second) / 100);
        usersIncomes[_winner3].rewardIncome += (third - (20 * third) / 100);

        address(uint256(_winner1)).transfer(usersIncomes[_winner1].rewardIncome);
        address(uint256(_winner2)).transfer(usersIncomes[_winner2].rewardIncome);
        address(uint256(_winner3)).transfer(usersIncomes[_winner3].rewardIncome);

        totalAmountDistributed += rewardWallet;

        rewardWallet = 0;

        usersIncomes[users[_winner1].inviter].recycleFund += (10 * first) / 100;
        usersIncomes[users[_winner2].inviter].recycleFund += (10 * second) / 100;
        usersIncomes[users[_winner3].inviter].recycleFund += (10 * third) / 100;

        usersIncomes[users[_winner1].inviter].levelFund += (10 * first) / 100;
        usersIncomes[users[_winner2].inviter].levelFund += (10 * second) / 100;
        usersIncomes[users[_winner3].inviter].levelFund += (10 * third) / 100;
    }


    function distributeLevelReward() internal{
        //pending
    }

    function distributeLevelUpgradeAmount() internal{
        //pending
    }
    
    function getTotalAmountWithdrawn() internal view returns (uint256) {
        return totalAmountDistributed;
    }

    function getTotalUsers() internal view returns (uint256) {
        return totalUsers;
    }

    function getRewardWallet()internal view returns (uint256) {
        return rewardWallet;
    }
    function getLevelRewardWallet() internal view returns (uint256) {
        return levelRewardWallet;
    }

    function getDirectIncome(address _add) internal view returns (uint256){
        return usersIncomes[_add].directIncome;
    }

   function getUserInfo(uint256 _id)
        public
        view
        returns (
        address inviter,
        uint256 totalReferals,
        uint256 totalRecycles,
        uint256 dailyReferrals,
        uint256 levelsPurchased
        )
    {
        User memory user = users[users_ids[_id]];
        return (
            user.inviter,
            user.totalReferals,
            user.totalRecycles,
            user.dailyReferrals,
            user.levelsPurchased
        );
    }
    
    function getUsersIncomes(uint256 _id) internal view returns (
        uint256 directIncome,
        uint256 rewardIncome,
        uint256 levelIncome,
        uint256 recycleIncome,
        uint256 recycleFund,
        uint256 levelFund)
        {
        return (
            usersIncomes[users_ids[_id]].directIncome,
            usersIncomes[users_ids[_id]].rewardIncome,
            usersIncomes[users_ids[_id]].levelIncome,
            usersIncomes[users_ids[_id]].recycleIncome,
            usersIncomes[users_ids[_id]].recycleFund,
            usersIncomes[users_ids[_id]].levelFund
            );
    }
    function withDrawlevelFund() public {
        require(users[msg.sender].levelsPurchased == 10, "you cannot withdraw amount");

        address(uint256(msg.sender)).transfer(
            usersIncomes[msg.sender].levelFund
        );

        usersIncomes[msg.sender].levelFund = 0;
    }
   
     function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < 4) return _user;

        address[] memory referrals = new address[](20000);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        referrals[3] = users[_user].referral[3];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint256 i = 0; i < 20000; i++) {
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
}
