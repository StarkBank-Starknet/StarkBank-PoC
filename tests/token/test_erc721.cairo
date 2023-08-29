// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use array::{SpanTrait,ArrayTrait};
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

use StarkBank::token::erc721::erc721::{IERC721SafeDispatcher, IERC721SafeDispatcherTrait,IERC721MetadataSafeDispatcher, IERC721MetadataSafeDispatcherTrait};


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

    '**** print constructor test ***'.print();

    let (caller, erc721) = setup_test_env();
    let reciever:ContractAddress = contract_address_const::<'reciever'>();


    assert(erc721.name().unwrap() == NAME, 'Name should be NAME');
    assert(erc721.symbol().unwrap() == SYMBOL, 'Symbol should be SYMBOL');
    assert(erc721.balance_of(caller).unwrap() == 1, 'Balance should be one');

    let token_id: u256 = 111;
    token_id.print();
    erc721.approve(reciever,token_id);
    assert((erc721.get_approved(token_id)).unwrap() == reciever, 'reciever should be approved');
    assert(erc721.owner_of(token_id).unwrap() == caller, 'OWNER should be caller');
}

#[test]
#[available_gas(20000000)]
fn test_owner(){
    //owner is caller from setup
    let (caller, erc721) = setup_test_env();
    let token_id: u256 = 111;

    assert(erc721.owner_of(token_id).unwrap() == caller, 'OWNER should be caller');
}

#[test]
#[available_gas(20000000)]
fn test_approve(){

    let reciever = contract_address_const::<'reciever'>();
    let (caller, erc721) = setup_test_env();

     let token_id: u256 = 111;
    token_id.print();
    erc721.approve(reciever,token_id);
    assert(erc721.get_approved(token_id).unwrap() == reciever, 'reciever should be approved');
}


// #[test]
// #[available_gas(20000000)]
// fn test_token_uri(){

//     let reciever = contract_address_const::<'reciever'>();
//     let (caller, erc721) = setup_test_env();

//     let token_id: u256 = 111;
//     let mut res: Span<felt252> = erc721.generate_token_uri(token_id);

//     let first = res.pop_front().unwrap();
//     assert(first == @'data:application/json,');

//}



fn setup_test_env() -> (ContractAddress, IERC721SafeDispatcher, ){

    let caller = contract_address_const::<'caller'>();

    let erc721_address: ContractAddress = deploy_erc721();
    // Get an interface to interact with the ERC20 contract.
    let erc721 = IERC721SafeDispatcher{contract_address: erc721_address};

    // Prank the caller.
    start_prank(erc721_address, caller);
    
    (caller, erc721)

}


fn deploy_erc721() -> ContractAddress{

    let caller = contract_address_const::<'caller'>();

    let class_hash = declare('ERC721');
    let mut constructor_calldata = array![];

    constructor_calldata.append(NAME);
    constructor_calldata.append(SYMBOL);
    constructor_calldata.append(caller.into());
    let token: u256 = 111;
    constructor_calldata.append(token.low.into());
    //(token.high).print();
    //token.low.print();
    constructor_calldata.append(token.high.into());

    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @constructor_calldata};

    let contract_address: ContractAddress = deploy(prepared).unwrap();

    contract_address
}

