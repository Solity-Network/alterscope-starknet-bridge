// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "src/StarknetMessagingLocal.sol";
import "src/BridgedERC20.sol";
import "src/L1Bridge.sol";

/**
   Deploys only the StarknetMessagingLocal contract.
*/
contract LocalSetup is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ACCOUNT_PRIVATE_KEY");

        string memory json = "local_testing";

        vm.startBroadcast(deployerPrivateKey);

        // Deploy StarknetMessagingLocal contract only
        address snLocalAddress = address(new StarknetMessagingLocal());
        vm.serializeString(json, "snMessaging_address", vm.toString(snLocalAddress));

        vm.stopBroadcast();

        // Save deployment information to JSON
        string memory data = vm.serializeBool(json, "success", true);
        string memory localLogs = "./logs/";
        vm.createDir(localLogs, true);
        vm.writeJson(data, string.concat(localLogs, "local_setup.json"));
    }
}

contract DeployBridgedERC20 is Script {
    function run() public {
        // Get the deployer's private key from environment variable or set it directly for local tests
        uint256 deployerPrivateKey = vm.envUint("ACCOUNT_PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the BridgedERC20 contract without interacting with it
        BridgedERC20 bridgedToken = new BridgedERC20(msg.sender);

        // Optionally log the deployed contract address
        console.log("BridgedERC20 deployed at:", address(bridgedToken));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}

contract DeployL1Bridge is Script {
    function run() public {
        // Get the deployer's private key from the environment
        uint256 deployerPrivateKey = vm.envUint("ACCOUNT_PRIVATE_KEY");

        // Get the Starknet Core Messaging Contract and L1 Token Address from environment
        address snMessaging = vm.envAddress("SN_MESSAGING_ADDRESS");
        address l1TokenAddress = vm.envAddress("L1_TOKEN_ADDRESS");

        // Begin broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the L1Bridge contract with the provided Starknet messaging and L1 token addresses
        L1Bridge l1Bridge = new L1Bridge(snMessaging, l1TokenAddress);

        // Log the deployed contract address to the console
        console.log("L1Bridge deployed at:", address(l1Bridge));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}


contract TransferOwnership is Script {
    function run() public {
        // Get the deployer's private key from the environment variable
        uint256 deployerPrivateKey = vm.envUint("ACCOUNT_PRIVATE_KEY");

        // Get the L1 Bridge Address from environment variable
        address newOwner = vm.envAddress("L1_BRIDGE_ADDRESS");

        // Get the deployed ERC20 token address from environment (or set it directly here)
        address bridgedTokenAddress = vm.envAddress("L1_TOKEN_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Interact with the already deployed BridgedERC20 contract
        BridgedERC20 bridgedToken = BridgedERC20(bridgedTokenAddress);

        // Transfer ownership to the new owner (L1 Bridge Address)
        bridgedToken.transferOwnership(newOwner);

        // Log the new ownership details
        console.log("Ownership of BridgedERC20 transferred to:", newOwner);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
