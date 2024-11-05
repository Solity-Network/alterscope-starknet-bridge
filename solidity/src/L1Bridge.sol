// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BridgedERC20.sol";
import "starknet/IStarknetMessaging.sol";

// Define some custom error as an example.
// It saves a lot's of space to use those custom error instead of strings.
error InvalidPayload();

/**
 * @title L1Bridge
 * @notice The L1Bridge contract enables bridging of tokens between Ethereum (L1) and StarkNet (L2).
 * It handles token minting on Ethereum upon receiving messages from StarkNet and burns tokens
 * on Ethereum while sending messages to StarkNet.
 */
contract L1Bridge{

    IStarknetMessaging private _snMessaging;  // Interface for messaging with StarkNet
    BridgedERC20 public _l1Token;  // The ERC20 token being bridged

    event TokensBridgedToL1(address indexed recipient, uint256 amount);
    event TokensBridgedBackToL2(address indexed sender, uint256 amount);

    /**
     * @notice Constructor to initialize the bridge with messaging contract and token.
     * @param snMessaging The address of StarkNet Core contract responsible for cross-chain messaging.
     * @param l1Token The address of the BridgedERC20 token contract on Ethereum.
     */
    constructor(address snMessaging, address l1Token ) {
        _snMessaging = IStarknetMessaging(snMessaging);
        _l1Token = BridgedERC20(l1Token);
    }

    /**
     * @notice Processes a message from StarkNet, minting tokens on Ethereum for the recipient.
     * @param l2Sender The address on StarkNet that initiated the message.
     * @param payload The payload containing recipient and amount details.
     */
    function withdraw(
        uint256 l2Sender,
        uint256[] calldata payload
    ) external {

        // Consumes the message from L2, ensuring it's valid and has not been used before
        _snMessaging.consumeMessageFromL2(l2Sender, payload);

        // Check that payload contains exactly two items: recipient address and token amount
        if (payload.length != 2) {
            revert InvalidPayload();
        }

        // Decode the payload:
        // payload[0]: Ethereum address as felt (252-bit), decode it to 160-bit address
        // payload[1]: Token amount as felt (252-bit)
        
        address l1Recipient = address(uint160(payload[0]));  // Convert felt to Ethereum address
        uint256 amount = payload[1];  // Token amount (remains uint256)

        // Mint the specified amount of tokens to the recipient on L1
        _l1Token.mint(l1Recipient, amount);

        // Emit event for successful bridging to L1
        emit TokensBridgedToL1(l1Recipient, amount);
    }


    /**
     * @notice Burn the tokens on L1 and send a message back to L2, initiating a transfer back to StarkNet.
     * @param contractAddress Bridge contract address on L2.
     * @param selector The function selector on Bridge contract address on L2. (Check out Q/A section for more detail)
     * @param amount The amount of tokens to be bridged.
     * @param l2Recipient The recipient address on L2 as felt (uint256).
     */
    function initiate_withdraw(
        uint256 contractAddress,
        uint256 selector,
        uint256 amount,
        uint256 l2Recipient
    ) external payable {
        
        // Burn the tokens on L1
        _l1Token.burn(msg.sender, amount);

        // Prepare the payload for the message to L2
        uint256[] memory payload = new uint256[](2);
        payload[0] = l2Recipient;
        payload[1] = amount;  

        // Send the message back to L2
        _snMessaging.sendMessageToL2{value: msg.value}(
            contractAddress,
            selector,
            payload
        );

        // Emit event to log the bridge-back action to StarkNet
        emit TokensBridgedBackToL2(msg.sender, amount);
    }
}
