use starknet::syscalls::send_message_to_l1_syscall;
use starknet::ContractAddress;
use starknet::EthAddress;

/// A custom struct `MyData`, holding two fields (`a` and `b`) which is already serializable as `felt252` is serializable.
#[derive(Drop, Serde)]
struct MyData {
    a: felt252, 
    b: felt252,
}

#[starknet::interface]
trait IL2Bridge<TContractState> {
    fn deposit(ref self: TContractState, data: MyData) -> bool;
}

#[starknet::interface]
trait IERC20<TContractState>{
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256
    );
    fn transfer(ref self: TContractState, to: ContractAddress, amount: u256);
}

#[starknet::contract]
mod l2bridge {
    use super::{IL2Bridge, MyData};
    use super::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::get_caller_address;  // Gets the caller's address in transactions
    use starknet::get_contract_address; // Gets the address of the current contract
    use starknet::{EthAddress, SyscallResultTrait, ContractAddress};
    use core::num::traits::Zero;  // Used for checking numerical zero values
    use starknet::syscalls::send_message_to_l1_syscall;  // Sends messages to Ethereum (L1)

    // Define the contract storage to hold the L1 bridge and token addresses
    #[storage]
    struct Storage {
        _l1_bridge_address: EthAddress,       // Ethereum (L1) bridge address
        _token_address: ContractAddress,      // Token address on StarkNet (L2)
    }


    // Event that logs messages sent to Ethereum (L1) for tracking purposes.
    #[event]
    fn LogMessageToL1(to_address: felt252, data: Array<felt252>) {
    }

    // Event for logging token transfers from L2 to L1.
    #[event]
    fn TokensTransferredBack(l1_address: felt252, recipient: ContractAddress, amount: u256) {
    }
    
    // Contract constructor which is initialized with L1 bridge and token addresses.
    #[constructor]
    fn constructor(ref self: ContractState, l1BridgeAddress: EthAddress, l2TokenAddress: ContractAddress) {
        self._l1_bridge_address.write(l1BridgeAddress);
        self._token_address.write(l2TokenAddress);
    }


    // L1 handler function for initiating withdrawals, triggered by messages from L1.
    #[l1_handler]
    fn initiate_withdraw(ref self: ContractState, from_address: felt252, data: MyData) -> bool {

        let amount: u256 = data.b.into();  // Convert data field `b` into an amount of tokens
        let recipient_address: ContractAddress = data.a.try_into().unwrap(); // Convert `a` to a StarkNet address

        // Transfer the specified token amount to the recipient address on L2
        let erc20_dispatcher = IERC20Dispatcher { contract_address: self._token_address.read() };
        erc20_dispatcher.transfer(recipient_address, amount);
        
        // Emit an event for logging purposes (optional)
        TokensTransferredBack(
            l1_address: from_address,
            recipient: recipient_address,
            amount: amount
        );

        true
    }

    #[abi(embed_v0)]
    impl L2BridgeImpl of super::IL2Bridge<ContractState> {
       
        // Function for deposits from L1 to L2, handling token transfers and messaging.
        fn deposit(ref self: ContractState, data: MyData) -> bool {

            let amount: u256 = data.b.into(); 

            // Transfer tokens from caller's address to the contract itself on L2
            let erc20_dispatcher = IERC20Dispatcher { contract_address: self._token_address.read() };
            erc20_dispatcher.transfer_from(get_caller_address(), get_contract_address(), amount);

            // Serialize `MyData` struct (convert to a format for message sending)
            let mut buf: Array<felt252> = array![];
            data.serialize(ref buf);

            // Log the message to L1 with the recipient address and serialized data
            LogMessageToL1(self._l1_bridge_address.read().into(), buf.clone());

            // Send the serialized message to L1, bridging the transaction
            send_message_to_l1_syscall(self._l1_bridge_address.read().into(), buf.span()).unwrap_syscall();

            true
        }
    }
}
