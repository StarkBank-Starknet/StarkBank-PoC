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
use snforge_std::{ PreparedContract, declare, deploy, PrintTrait };

use StarkBank::token::erc721::ERC721::{
    Approval, ApprovalForAll, ERC721Impl,
    ERC721MetadataImpl, InternalImpl, Transfer,
};
use StarkBank::token::erc721::ERC721;
use StarkBank::token::erc721;

use StarkBank::token::erc721::erc721::{IERC721SafeDispatcher, IERC721SafeDispatcherTrait};


const NAME: felt252 = 'nftGus';
const SYMBOL: felt252 = 'abe';
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

// fn STATE() -> ERC721::ContractState {
//     ERC721::contract_state_for_testing()
// }


// fn setup() -> ERC721::ContractState {
//     'print setup'.print();
//     let mut state = STATE();
//     InternalImpl::initializer(ref state, NAME, SYMBOL);
//     InternalImpl::_mint(ref state, OWNER(), TOKEN_ID);
//     testing::pop_log_raw(ZERO());
//     state
// }

#[test]
#[available_gas(20000000)]
fn test_constructor() {

    let (owner, erc721) = setup_test_env();

    'print constructor test'.print();

    let caller = contract_address_const::<'caller'>();


    assert(erc721.name().unwrap() == NAME, 'Name should be NAME');
    'pass 1'.print();
    assert(erc721.symbol().unwrap() == SYMBOL, 'Symbol should be SYMBOL');
    'pass 2'.print();
    assert(erc721.balance_of(caller).unwrap() == 1, 'Balance should be one');
    'pass 3'.print();
    let token: u256 = 0x6F.into();
    token.print();
    assert(erc721.owner_of(token).unwrap() == caller, 'OWNER should be owner');
}


fn setup_test_env() -> (ContractAddress, IERC721SafeDispatcher, ){

    let erc721_address: ContractAddress = deploy_erc721();
    // Get an interface to interact with the ERC20 contract.
    let erc721 = IERC721SafeDispatcher{contract_address: erc721_address};

    // Prank the caller.
    start_prank(erc721_address, OWNER());
    
    (OWNER(), erc721)

}


fn deploy_erc721() -> ContractAddress{

    let caller = contract_address_const::<'caller'>();

    let class_hash = declare('ERC721');
    let mut constructor_calldata = array![];

    constructor_calldata.append(NAME);
    constructor_calldata.append(SYMBOL);
    constructor_calldata.append(caller.into());
    let token_felt252_low : felt252 = 0x6;
    constructor_calldata.append(token_felt252_low);
    let token_felt252_high : felt252 = 0xF;
    constructor_calldata.append(token_felt252_high);

    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @constructor_calldata};

    let contract_address: ContractAddress = deploy(prepared).unwrap();

    contract_address
}

