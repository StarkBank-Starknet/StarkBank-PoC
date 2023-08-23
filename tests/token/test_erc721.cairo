// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use zeroable::Zeroable;

use starknet::{
    ContractAddress, get_caller_address, contract_address_const,
    ClassHash,testing,
};
use snforge_std::PrintTrait;
use cheatcodes::PreparedContract;

use StarkBank::token::erc721::ERC721::{
    Approval, ApprovalForAll, ERC721Impl,
    ERC721MetadataImpl, InternalImpl, Transfer,
};
use StarkBank::token::erc721::ERC721;
use StarkBank::token::erc721;


const NAME: felt252 = 'nftGus';
const SYMBOL: felt252 = 'ONE';
const TOKEN_ID: u256 = 123;

fn ZERO() -> ContractAddress {
    contract_address_const::<0>()
}

fn CALLER() -> ContractAddress {
    contract_address_const::<'CALLER'>()
}

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn STATE() -> ERC721::ContractState {
    ERC721::contract_state_for_testing()
}

fn setup() -> ERC721::ContractState {
    'print setup'.print();
    let mut state = STATE();
    InternalImpl::initializer(ref state, NAME, SYMBOL);
    InternalImpl::_mint(ref state, OWNER(), TOKEN_ID);
    testing::pop_log_raw(ZERO());
    state
}

#[test]
#[available_gas(20000000)]
fn test_constructor() {
    'print constructor test'.print();
    let mut state = STATE();
    ERC721::constructor(ref state, NAME, SYMBOL, OWNER(), TOKEN_ID);
    'Print short string:'.print();
    assert(ERC721MetadataImpl::name(@state) == NAME, 'Name should be NAME');
    assert(ERC721MetadataImpl::symbol(@state) == SYMBOL, 'Symbol should be SYMBOL');
    assert(ERC721Impl::balance_of(@state, OWNER()) == 1, 'Balance should be one');
    assert(ERC721Impl::owner_of(@state, TOKEN_ID) == OWNER(), 'OWNER should be owner');

}


