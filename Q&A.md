# StarkNet Development: Common Questions & Solutions

This guide provides answers to frequently asked questions and minor issues encountered during StarkNet development.

## How do I obtain the function selector for a function in StarkNet?

In StarkNet, each function in a contract has a unique identifier called a "function selector." This selector is derived
from the hash of the function name and is used to reference the function in cross-layer calls.

### Solution

To obtain the function selector for any function in your contract, use the `get_selector_from_name` function from
`starknet_py.utils.typed_data`. Here’s how to calculate the selector.

### Example

This example shows how to calculate the selector for a function named `msg_handler_struct`.

#### Code

```python
from starknet_py.utils.typed_data import get_selector_from_name

# Specify the function name (replace with the actual name in your contract) 
function_name = "msg_handler_struct"

# Calculate the selector
selector = get_selector_from_name(function_name)
print(f"StarkNet Selector: {hex(selector)}")
```

#### Output

After running the code, you should see output similar to this:

```plaintext
StarkNet Selector: 0xf1149cade9d692862ad41df96b108aa2c20af34f640457e781d166c98dc6b0
```

### Use Case

The provided code can be used to obtain the selector for any function in your contract. It is particularly useful if you
need to change the function name `msg_handler_struct` in `l2bridge.cairo`. By using this code, you can generate the
correct selector for any new function name, ensuring it remains identifiable in cross-layer interactions.

## How do I verify the message hash when sending messages from StarkNet to Ethereum?

When sending messages from StarkNet to Ethereum, calculating the message hash directly can help ensure it is correctly
formatted. Verifying the hash can help identify encoding issues if the message fails to decode properly on Ethereum.

### Solution

The script below demonstrates how to calculate the message hash. By hashing the message on both the StarkNet (sender)
and Ethereum (receiver) sides, you can compare the hashes to verify the message's integrity.

#### Code

```python
import hashlib
from eth_abi import encode


def calculate_message_hash(l2Sender, payload):
    # Encode the L2 sender and payload in ABI format for consistency
    encoded_message = encode(
        ['uint256', 'uint256', 'uint256', 'uint256'],
        [l2Sender, payload[0], payload[1], payload[2]]
    )

    # Calculate the keccak256 hash of the encoded message
    message_hash = hashlib.sha256(encoded_message).hexdigest()
    return message_hash


# Example values
l2_sender = 0x05d1fb1f790c860347cfbdcc9d5376f935e3fbff9dd4e9972f1bef5219f4ac99
payload = [5000, 0, 1390849295786071768276380950238675083608645509734]

message_hash = calculate_message_hash(l2_sender, payload)
print(f"Message Hash: {message_hash}")
```

### Explanation

- **Encoding**: The function encodes `l2Sender` and `payload` into ABI format, ensuring it aligns with Ethereum’s
  expected data structure.
- **Hashing**: After encoding, the function calculates the `sha256` hash of the message, generating a hash representing
  the message's unique data signature.
- **Comparison**: By calculating this hash on both StarkNet and Ethereum, you can verify that the message was
  transmitted correctly.

#### Output

This code will output the hash in hexadecimal format:

```plaintext
Message Hash: 99302170e9e13e39840e878431784e42085b21d43132a19b01d49e30c169f90c
```

### Use Case

If you encounter decoding issues on Ethereum or are unsure if the message was encoded correctly, calculating the hash
serves as a verification step. Confirming matching hashes on both sides ensures data integrity and correctness.

## Will my deployment addresses match the examples in the repository?

If you use the repository’s code without modifications, your deployment addresses are likely to match. However, if you
modify, build, or redeploy the contracts, the addresses will differ.

## How can I get the `felt` version of my wallet address?

To use wallet addresses in this tutorial, you need the `felt` (field element) format. You can easily convert any
Ethereum or StarkNet address using the [Stark Utils Converter](https://www.stark-utils.xyz/converter).