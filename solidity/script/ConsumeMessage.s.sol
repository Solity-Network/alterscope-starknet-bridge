// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "src/L1Bridge.sol";


/**
 * @notice A script to receive tokens from StarkNet
 */
contract ConsumeMessage is Script {
    uint256  _privateKey;
    address  _l1BridgeAddress;
    uint256  _l2BridgeAddress;  
    uint256  recipient;         
    uint256  amount;           

    function setUp() public {
        _privateKey = vm.envUint("ACCOUNT_PRIVATE_KEY");  
        _l1BridgeAddress = vm.envAddress("L1_BRIDGE_ADDRESS");  
        _l2BridgeAddress = vm.envUint("L2_BRIDGE_ADDRESS");  
        recipient = vm.envUint("ACCOUNT_ADDRESS");         
        amount = vm.envUint("AMOUNT");                      
    }

    function run() public {
        vm.startBroadcast(_privateKey);  // Start broadcasting the transaction

        // In the example, we've sent a message with serialize MyData.
        uint256[] memory payload = new uint256[](2);

        payload[0] = recipient;        // Recipient's Ethereum address (in felt)
        payload[1] = amount;           // Token amount 

        // Call the L1Bridge contract's withdraw function
        L1Bridge(_l1BridgeAddress).withdraw(
            _l2BridgeAddress,  // L2 sender (L2 bridge address in felt)
            payload            // Payload: [recipient, amount]
        );

        vm.stopBroadcast();  // Stop broadcasting the transaction
    }
}
