// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.7.0 (token/erc721/interface.cairo)

use array::SpanTrait;
use starknet::ContractAddress;

const IERC721_ID: felt252 = 0x33eb2f84c309543403fd69f0d0f363781ef06ef6faeb0131ff16ea3175bd943;
const IERC721_METADATA_ID: felt252 =
    0x6069a70848f907fa57668ba1875164eb4dcee693952468581406d131081bbd;
const IERC721_RECEIVER_ID: felt252 =
    0x3a0dff5f70d80458ad14ae37bb182a728e3c8cdda0402a5daa86620bdf910bc;

#[starknet::interface]
trait IERC721<TState> {
    /// Returns the name of the token.
    fn name(self: @TState) -> felt252;
    /// Returns the symbol of the token, usually a shorter version of the name.
    fn symbol(self: @TState) -> felt252;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    // fn safe_transfer_from(
    //     ref self: TState,
    //     from: ContractAddress,
    //     to: ContractAddress,
    //     token_id: u256,
    //     data: Span<felt252>
    // );
    fn approve(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
}


//
// IERC721Metadata
//
#[starknet::interface]
trait IERC721Metadata<TState> {
    fn token_uri(self: @TState, token_id: u256) -> felt252;
}

//
// ERC721Receiver
//
#[starknet::interface]
trait IERC721Receiver<TState> {
    fn on_erc721_received(
        self: @TState,
        operator: ContractAddress,
        from: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    ) -> felt252;
}
