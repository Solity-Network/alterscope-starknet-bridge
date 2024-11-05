// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract BridgedERC20 is ERC20, Ownable {
    // Sets the token name to "BridgedToken" and symbol to "BRG"
    // Initializes ownership for access control
    constructor(address initialOwner) ERC20("BridgedToken", "BRG") Ownable(initialOwner) {}

    // Function for the owner to mint (create) new tokens.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Function for the owner to burn (destroy) tokens from a specific address.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}