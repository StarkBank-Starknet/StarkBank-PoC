// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.7.0 (token/erc721/interface.cairo)

use array::SpanTrait;
use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TState> {
    /// Returns the name of the token.
    fn name(self: @TState) -> felt252;
    /// Returns the symbol of the token, usually a shorter version of the name.
    fn symbol(self: @TState) -> felt252;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    //fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn approve(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
     fn mint(ref self: TState, to: ContractAddress, token_id: u256, collateral_ratio: u256);
}


//
// IERC721Metadata
//
#[starknet::interface]
trait IERC721Metadata<TState> {
        //fn token_uri(ref self: TState, token_id: u256) -> Span<felt252>;
        fn generate_token_uri(ref self: TState, token_id: u256,  collateral_ratio: u256) ->Span<felt252>;

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
