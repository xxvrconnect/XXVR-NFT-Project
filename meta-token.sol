// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract MetaToken is ERC20 {

    address admin;

    constructor(uint256 initialSupply) public ERC20("XXVR", "COIN") {
        _mint(msg.sender, initialSupply * (10**18));
        admin = msg.sender;
    }

    function mintMore(uint256 supply) public {
        require(msg.sender == admin, "Invalid user.");
        _mint(msg.sender, supply);
    }
}