//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./SlicedStructs.sol";


contract Sliced is ERC20Burnable,Ownable,Pausable {


	address constant team = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    	address public  sale = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    	address constant marketing = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
	address constant airdrop = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
	address constant liquidity = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
	address constant reward = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
	address constant dev = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
	address constant treasury = 0xBcd4042DE499D14e55001CcbB24a551F3b954096;


	mapping(address=>bool) public blacklistedAddresses;
	mapping(address=>bool) public admins;


	mapping(address => WalletTokens) public walletTokens;


    modifier isNotBlacklisted(address _from,address _to) {
      require(!blacklistedAddresses[_from], "SLICED::Sender is blacklisted");
	  require(!blacklistedAddresses[_to], "SLICED::Receiver is blacklisted");
      _;
    }
	 modifier onlyAdmin() {
	   require(admins[msg.sender], "SLICED::You Are not Admin");
      _;
    }

	 constructor(string memory _name, string memory _symbol,uint _supply,address _sale) ERC20(_name, _symbol) {
         sale = _sale;
		uint nowDate = block.timestamp;
		walletTokens[team] = WalletTokens((_supply*15)/100,((_supply*15)/100)/15,Vesting(0,0,12,15,3),nowDate+(12 * 30 days));
		walletTokens[marketing] = WalletTokens((_supply*5)/100,((_supply*5)/100)/12,Vesting(0,0,3,12,3),nowDate+(3 * 30 days));
		walletTokens[airdrop] = WalletTokens((_supply*3)/100,((_supply*3)/100)/2,Vesting(0,0,3,2,1),nowDate+(3 * 30 days));
		walletTokens[liquidity] = WalletTokens((_supply*7)/100,((_supply*7*25)/10000)/24,Vesting(0,25,0,24,1),nowDate+30 days);
		walletTokens[liquidity].lockedAmount -= (_supply*7*25)/10000;
		_mint(liquidity, (_supply*7*25)/10000);
		walletTokens[reward] = WalletTokens((_supply*20)/100,((_supply*20)/10000)/24,Vesting(0,1,4,24,1),nowDate+(4 *30 days));
		walletTokens[dev] = WalletTokens((_supply*25)/100,((_supply*25)/10000)/24,Vesting(0,0,6,24,1),nowDate+(6 *30 days));
		walletTokens[treasury] = WalletTokens((_supply*5)/100,((_supply*5)/10000)/24,Vesting(0,0,6,24,1),nowDate+(6 *30 days));
		_mint(sale, (_supply*20)/100);
		_mint(address(this),_supply-totalSupply());

    }


	function claimTokens() external {
		uint8 durationType = walletTokens[msg.sender].vestingParams.durationType;
		require(durationType>0,"Invalid User");
		require(walletTokens[msg.sender].nextClaimDate <= block.timestamp,"Invalid Claiming Date");
		uint mDiff = (block.timestamp - walletTokens[msg.sender].nextClaimDate) / 60 / 60 / 24 / 30;
		uint vDiff = mDiff / durationType;
		if(vDiff>0) walletTokens[msg.sender].amountToClaim *= vDiff; 
		require(walletTokens[msg.sender].amountToClaim>0,"Nothing to claim");
		walletTokens[msg.sender].nextClaimDate += (durationType * (vDiff + 1)) * 30 days;
		walletTokens[msg.sender].lockedAmount -= walletTokens[msg.sender].amountToClaim;
		walletTokens[msg.sender].amountToClaim = (walletTokens[msg.sender].lockedAmount == 0)?0:walletTokens[msg.sender].amountToClaim;
		_transfer(address(this),msg.sender,walletTokens[msg.sender].amountToClaim);

    }

    function updateUserState(address _user,bool _state) external onlyAdmin {
		require(_user!=address(0),"SLICED::Address NULL");
        blacklistedAddresses[_user] = _state;
    }
    
	function updateAdmin(address _user,bool _state) external onlyOwner {
		require(_user!=address(0),"SLICED::Address NULL");
        admins[_user] = _state;
    }  



	function pause() external  onlyOwner {
        _pause();
    }

	function unpause() external  onlyOwner {
        _unpause();
    }  

	function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal isNotBlacklisted(_from,_to) virtual  override(ERC20) {
		require(!paused(), "SLICED::Token transfer while paused");
        super._beforeTokenTransfer(_from, _to, _amount);
    }

}
