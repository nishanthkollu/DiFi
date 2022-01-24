// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICoin.sol";

//The initial stablecoin will be an ERC20 compatible token
contract StableCoinToken is ERC20, Ownable, ICoin {
    uint256 public ethPrice;
    uint256 supplyTotal;

    //The initial stable coin will have a symbol of "AUDC" and a name of "AUD Stablecoin"
    constructor() ERC20("AUD Stablecoin","AUDC") {
    }

    using Counters for Counters.Counter;
    Counters.Counter private userIDs;
    mapping(address => uint256) balances;
    mapping(uint => Vault) public users;
    mapping(address => uint256) public userIDList;

    struct Vault {
        uint256 collateralAmount; // The amount of collateral held by the vault contract
        uint256 debtAmount; // The amount of stable coins that were minted against the collateral
    }

    // setting ETH Price based on required value as parameter
    function setETHPrice(uint256 priceETH) external {
        ethPrice = priceETH;
    }

    //Setting Vault with parameters as Collateral Amount and Debt Amount
    function setVault(uint256 collateralAmount, uint256 debtAmount) public {
        userIDs.increment();
        uint256 newUserID = userIDs.current();
        userIDList[msg.sender] = newUserID;
        users[newUserID] = Vault(
            collateralAmount,
            debtAmount
        );
   }
   
   //Retrieving Vault based on userid
   function getVault() public view returns (Vault memory vault) {
      return users[getuseridaccordingtoaddress()];
   }

   //Checking if user exists
   function checkuserexists(uint256 userID) public view returns (bool) {
      return users[userID].collateralAmount != 0;
   }

    //Retrieving Current UserID
   function getUserID() external view returns (uint256) {
      return userIDs.current();
   }

    //Retrieving UserId based on address
   function getuseridaccordingtoaddress() public view returns (uint256) {
        return userIDList[msg.sender];
   }

    // By depositing collateral, a user will open a vault or increase the debt in their existing vault
    function deposit(uint256 amountToDeposit) external {
        if(checkuserexists(getuseridaccordingtoaddress())){
            Vault memory vault = getVault();

            //If a user's vault collateral ratio drops below 100% (ie the price of AUD/ETH increases), 
            //depositing into the vault will not mint more AUDC 
            //(Note: If ETH price doesn't change)
            if(vault.debtAmount / vault.collateralAmount == ethPrice){
                mint(msg.sender, amountToDeposit * ethPrice);
                //Collateral is stored as Ethers
                vault.collateralAmount += amountToDeposit;
                //Debt Amount is stored as ERC20 Tokens 
                vault.debtAmount += amountToDeposit * ethPrice;
                users[getuseridaccordingtoaddress()] = vault;
            }
            else{
                //If a user's vault collateral ratio is over 100% (the price of AUD/ETH dropped) 
                //they are still required to repay all the AUDC minted to withdraw 100% of their collateral.
                //(Note: Calculating with new ETH Price)
                uint256 diffAmount = (vault.collateralAmount + amountToDeposit) * ethPrice;
                mint(msg.sender, diffAmount - vault.debtAmount);
                vault.collateralAmount += amountToDeposit;
                vault.debtAmount += (diffAmount - vault.debtAmount);
                users[getuseridaccordingtoaddress()] = vault;
            }
        }
        else{
            setVault(amountToDeposit, amountToDeposit * ethPrice);
            mint(msg.sender, amountToDeposit * ethPrice);
        }
    }

    // A user must be able to repay an amount AUDC and receive some amount of their collateral in return
    function withdraw(uint256 repaymentAmount) external{
        require(checkuserexists(getuseridaccordingtoaddress()), "User does not exist");
        Vault memory vault = getVault();
        require(vault.debtAmount >= repaymentAmount, "repaymentAmount exceeds debtAmount");
        if(vault.debtAmount >= repaymentAmount){
            vault.debtAmount -= repaymentAmount;
            //The amount of collateral that a user can withdraw per AUDC repaid depends 
            //on the current AUD/ETH price
            vault.collateralAmount -= repaymentAmount / ethPrice;
            users[getuseridaccordingtoaddress()] = vault;
            burn(msg.sender, repaymentAmount);
        }
    }

    // Issue/Mint the Tokens
    function mint(address account, uint256 amount) public override returns (bool){
        supplyTotal += amount;
        balances[account] += amount;
        return true;
    }

    // Burn the Tokens
    function burn(address account, uint256 amount) public override returns (bool){
        supplyTotal -= amount;
        balances[account] -= amount;
        return true;
    }

    //A user must be able to retrieve an estimated amount of AUDC required to retrieve their collateral on deposit
    function estimateCollateralAmount(uint256 repaymentAmountToken) external view returns(uint256 collateralAmount){
        uint256 estimatedCollateralAmount = repaymentAmountToken / ethPrice;
        return estimatedCollateralAmount;
    }

    //A user must be able to retrieve an estimate of how much AUDC a given amount of collateral would mint
    function estimateTokenAmount(uint256 depositAmount) external view returns(uint256 tokenAmount){
        uint256 estimatedTokenAmount = depositAmount * ethPrice;
        return estimatedTokenAmount;
    }

    //Retrieves Token Balance of current user
    function balanceOf() external view returns (uint256) {
        return balances[msg.sender];
    }

    //Retrieves Total supply Tokens
    function totalSupply() public override view returns (uint256) {
        return supplyTotal;
    }

}
