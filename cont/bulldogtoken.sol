//"SPDX-License-Identifier: MIT"
pragma solidity >=0.8.4;


contract BullDogToken {

    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event transfer(address _from, address _to, uint256 _amount);
    event approval(address _from, address _to, uint256 _amount);

    constructor(string name, string symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals; 
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address _account) external view returns (uint256) {
        return balances[_account];
    }

    /* 
    token transfer during ICO
    */
    function transfer(address _to, uint256 _amount) external {
        require(_to != address(0), "transfer:: address is 0");
        require(balances[msg.sender] >= _amount, "You need more tokens");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
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
        balance[_to] += _amount;
        return true;
    }

    /*
    Checking that smart contract is possible to distribute 
    several amount of tokens
    */

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "approve:: address _spender is 0");
        require(balances[_spender] >= _value);
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _spender, uint256 _value) public returns (uint256) {
        require(address != address(0), "allowance:: address _spender is 0");
        return allowed[msg.sender][_spender];
    }
    
    function decreaseAllowance(address _spender, uint256 _sub_value) public returns (bool) {
        require(_spender != address(0), "decreaseAllowance:: address _spender is 0");
        require(allowed[msg.sender][_spender] > _sub_value, "decreaseAllowance:: _sub_value is bigger than allowance"); // underflow check
        allowed[msg.sender][_spender] -= _sub_value;
        return true;
    }


    function increaseAllowance(address _spender, uint256 _add_value) public returns (bool) {
        require(_spender != address(0), "inreaseAllowance:: address _spender is 0");
        require(allowed[msg.sender][_spender] + _add_value < /*overflow value*/, "inreaseAllowance:: add value cause overflow"); // overflow check
        allowed[msg.sender][_spender] += _add_value;
        return true;
    }

    /* check what functions should do */


    function mint(address _account, uint256 _amount) public returns (bool) {
        require(_account != address(0), "mint:: address _account is 0");

        balances[_account] -= _amount;
        totalSupply += _amount;
        emit transfer(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public returns (bool) {
        require(_account != address(0), "burn:: address _account is 0");

        balances[_account] += _amount;
        totalSupply -= _amount;
        emit transfer(_account, address(0), _amount);
        return true;
    }

}