// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ICoin.sol";

contract StableCoinToken is ERC20, ICoin, Ownable{
    constructor(string memory _name, string memory _symbol) ERC20("AUD Stablecoin","AUDC") {}

    using Counters for Counters.Counter;
    Counters.Counter private userIDs;

    struct Vault {
        uint256 collateralAmount; // The amount of collateral held by the vault contract
        uint256 debtAmount; // The amount of stable coin that was minted against the collateral
    }
     mapping(uint => Vault) public users;
     mapping(address => uint256) public userIDList;

    function setVault(uint256 A_collateralAmount, uint256 A_debtAmount) public {
        userIDs.increment();
        uint256 newUserID = userIDs.current();
        userIDList[msg.sender] = newUserID;
        users[newUserID] = Vault(
            A_collateralAmount,
            A_debtAmount
        );
   }

   function getVault() public view returns (Vault memory vault) {
      return users[getuseridaccordingtoaddress()];
   }

   function checkuserexists(uint256 userID) public view returns (bool) {
      return users[userID].collateralAmount != 0;
   }

   function getUserID() public view returns (uint256) {
      return userIDs.current();
   }

   function getuseridaccordingtoaddress() public view returns (uint256) {
        return userIDList[msg.sender];
   }

    function deposit(uint256 amountToDeposit) external {
        // uint256 temp_id =  getuseridaccordingtoaddress
        if(checkuserexists(getuseridaccordingtoaddress())){
            Vault memory vault = getVault();
            vault.collateralAmount += amountToDeposit;
            users[getuseridaccordingtoaddress()] = vault;
        }
        else{
            setVault(amountToDeposit, 0);
        }
    }

    function withdraw(uint256 repaymentAmount) external;

}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}