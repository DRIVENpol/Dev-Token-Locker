//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

// Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DevWalletLock is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    // Variables
    address public theToken;


    // Constructor
    constructor(
        address _theToken
    ) {
        theToken = _theToken;
    }

    // Structs
    struct DepositTokens {
        address token;
        uint256 amount;
        uint256 lockTime;
    }

    DepositTokens[] public deposits;

    // Events
    event Deposit (
        address token,
        uint256 amount,
        uint256 lockTime
    );

    // OnlyOwner functions
    function depositTokens(uint256 _amount, uint256 _lockTime) public onlyOwner() {
        // _lockTime = no. of weeks for lock
        uint256 _lock = _lockTime.mul(1 weeks);
        DepositTokens memory newDeposit = DepositTokens(theToken, _amount, _lock);

        deposits.push(newDeposit);

        IERC20(theToken).safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(theToken, _amount, _lockTime);
    }

    function withdrawFromDeposit(uint256 _depositId) public onlyOwner() {
        DepositTokens memory deposit = deposits[_depositId];
        require(block.timestamp >= deposit.lockTime, "Can't withdraw right now!");
        uint256 _balance = deposit.amount;
        deposit.amount = 0;
        address _owner = owner();
        IERC20(theToken).safeTransfer(_owner, _balance);
    }

    // For emergency only
        function withdrawFromDeposit_NoLimit(uint256 _depositId) public onlyOwner() {
        DepositTokens memory deposit = deposits[_depositId];
         uint256 _balance = deposit.amount;
        deposit.amount = 0;
        address _owner = owner();
        IERC20(theToken).safeTransfer(_owner, _balance);
    }

    function withdrawAnyToken(address _tokenAddress) public onlyOwner() {
        require(_tokenAddress != theToken, "Can't withdraw locked tokens like that!");
        uint256 _balance = IERC20(_tokenAddress).balanceOf(address(this));
        address _owner = owner();
        IERC20(_tokenAddress).safeTransfer(_owner, _balance);
    }

    // Getters for web interface
    function getTotalDeposits() public view returns (uint256) {
        uint256 _size = deposits.length;
        return _size;
    }

    function getUnlockTimeForDeposit(uint256 _depositId) public view returns (uint256) {
        DepositTokens memory deposit = deposits[_depositId];
        require(deposit.lockTime >= block.timestamp, "Deposit unlocked!");

        uint256 _unlockTime = deposit.lockTime.sub(block.timestamp);
        
        return _unlockTime;
    }

    function getAmountForDeposit(uint256 _depositId) public view returns (uint256) {
        DepositTokens memory deposit = deposits[_depositId];
        require(deposit.lockTime >= block.timestamp, "Deposit unlocked!");

        uint256 _amount = deposit.amount;
        
        return _amount;
    }

    function getDepositSummary(uint256 _depositId) public view returns (uint256, uint256) {
        DepositTokens memory deposit = deposits[_depositId];
        require(deposit.lockTime >= block.timestamp, "Deposit unlocked!");

        uint256 _unlockTime = deposit.lockTime.sub(block.timestamp);
        uint256 _amount = deposit.amount;

        return (_unlockTime, _amount);
    }

}
