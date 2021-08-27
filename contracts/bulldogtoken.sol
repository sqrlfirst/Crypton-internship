//"SPDX-License-Identifier: MIT"
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import 'hardhat/console.sol';

contract BullDogToken is ERC20{

    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10**decimals;

    string public name = "BullDogToken";
    string public symbol = "BDT";
    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event transfer_(address _from, address _to, uint256 _amount);
    event approval(address _from, address _to, uint256 _amount);

    constructor(){
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

   

    function balanceOf(address _account) external view returns (uint256) {
        console.log('balance %s', balances[_account]);
        return balances[_account];
    }

    /* 
    token transfer during ICO
    */
    function transfer(address _to, uint256 _amount) external {
        require(_to != address(0), "transfer:: address is 0");
        require(balances[msg.sender] >= _amount, "transfer:: You need more tokens");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit transfer_(msg.sender, _to, _amount);
    }


    /* 
    transaction between users
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_from != address(0), "transferFrom:: address _from is 0");
        require(_to != address(0), "transferFrom:: address _to is 0");
        require(allowed[_from][_to] >= _amount, "transferFrom:: amount is not allowed");

        balances[_from] -= _amount;
        allowed[_from][_to] -= _amount;     // or decreaseAllowance ?
        balances[_to] += _amount;
        emit transfer_(_from, _to, _amount);
        return true;
    }

    /*
    Checking that smart contract is possible to distribute 
    several amount of tokens
    */

    function approve(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "approve:: address _to is 0");
        require(balances[msg.sender] >= _value, "approve:: balance is low");
        allowed[msg.sender][_to] = _value;
        console.log('Alloweded %s tokens', allowed[msg.sender][_to]);
        console.log('Sender address', msg.sender);
        console.log('Spender address', _to);
        emit approval(msg.sender, _to, _value);
        return true;
    }

    function allowance(address _to) public view returns (uint256) {
        require(_to != address(0), "allowance:: address _to is 0");
        console.log('Alloweded %s tokens', allowed[msg.sender][_to]);
        return allowed[msg.sender][_to];
    }
    
    function decreaseAllowance(address _to, uint256 _sub_value) public returns (bool) {
        require(_to != address(0), "decreaseAllowance:: address _to is 0");
        require(msg.sender != address(0), "decreaseAllowance:: sender address is 0");
        require(msg.sender != _to, "decreaseAllowance:: useless, addresses are the same"); // is it needed?
        require(allowed[msg.sender][_to] > _sub_value, "decreaseAllowance:: _sub_value is bigger than allowance"); // underflow check
        allowed[msg.sender][_to] -= _sub_value;
        return true;
    }


    function increaseAllowance(address _to, uint256 _add_value) public returns (bool) {
        require(_to != address(0), "inreaseAllowance:: address _to is 0");
        require(msg.sender != address(0), "inreaseAllowance:: address sender is 0");
        require(msg.sender != _to, "increaseAllowance:: useless adresses are the same");
        require(allowed[msg.sender][_to] + _add_value < balances[msg.sender], "inreaseAllowance:: resulted value is bigger than balance"); 
        allowed[msg.sender][_to] += _add_value;
        return true;
    }

    /* check what functions should do */


    function mint(address _account, uint256 _amount) public returns (bool) {
        require(_account != address(0), "mint:: address _account is 0");
        require(msg.sender == owner, "mint:: access denied");

        balances[_account] += _amount;
        totalSupply += _amount;
        emit transfer_(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public returns (bool) {
        require(_account != address(0), "burn:: address _account is 0");
        require(msg.sender == owner, "burn:: access denied");
        require(balances[_account] >= _amount, "burn:: _amount is bigger than balance");
        balances[_account] -= _amount;
        totalSupply -= _amount;
        emit transfer_(_account, address(0), _amount);
        return true;
    }

}