"SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.8.4;


contract BullDogToken {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public totalSupply = 100000000;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor() public {
        _name = "Bulldog Token";
        _symbol = "BDT";
        _decimals = 18; 
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
        require(balances[msg.sender] >= _amount, "You need more tokens");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }


    /* 
    transaction between users
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(allowed[_from][_to] >= _amount);
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
        require(balances[_spender] >= _value);
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    /*
    Checking that adress has tokens
    */
    function decreaseAllowance(address _spender, uint256 _sub_value) public returns (bool) {
        require(allowed[msg.sender][_spender] >= _sub_value); // underflow check
        allowed[msg.sender][_spender] -= _sub_value;
        return true;
    }


    function increaseAllowance(address _spender, uint256 _add_value) public returns (bool) {
        require(allowed[msg.sender][_spender] + _add_value < 2 ** 256); // overflow check
        allowed[msg.sender][_spender] += _add_value;
        return true;
    }

    function mint( ) {

    }

    function burn( ) {

    }

}