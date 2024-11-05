// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "src/L1Bridge.sol";


/**
 * @notice A script to send tokens to Starknet.
 */
contract BridgeTokens is Script {
    uint256 _privateKey;
    address _l1BridgeAddress;    
    uint256 _l2BridgeAddress;
    uint256  recipient;         
    uint256  amount;        

    address _starknetMessagingAddress;
    uint256 _l2Selector;

    function setUp() public {
        _privateKey = vm.envUint("ACCOUNT_PRIVATE_KEY");
        _l2BridgeAddress = vm.envUint("L2_BRIDGE_ADDRESS");  
        _l2Selector = vm.envUint("L2_SELECTOR_STRUCT");
        amount = vm.envUint("AMOUNT");                      
        recipient = vm.envUint("L2_ACCOUNT_FELT");         

        _l1BridgeAddress = vm.envAddress("L1_BRIDGE_ADDRESS");  
        _starknetMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
    }

    function run() public{
        vm.startBroadcast(_privateKey);

        // Remember that there is a cost of at least 20k wei to send a message.
        // Let's send 30k here to ensure that we pay enough for our payload serialization.
        // Call the L1Bridge contract's initiate_withdraw function

        L1Bridge(_l1BridgeAddress).initiate_withdraw{value: 30000}(
            _l2BridgeAddress,
            _l2Selector,
            amount,
            recipient);

        vm.stopBroadcast();
    }
}
