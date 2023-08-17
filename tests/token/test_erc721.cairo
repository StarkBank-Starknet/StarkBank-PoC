// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, contract_address_const,
    ClassHash,
};
use cheatcodes::PreparedContract;

use StarkBank::token::ERC721::{IERC721Dispatcher, IERC721DispatcherTrait};

#[test]
fn nft_is_mintable(){

    let name = 'Test Token';
    let symbol = 'TT';
    let (caller, erc20) = setup_test_environment(name, symbol);
    
    let recipient = contract_address_const::<'recipient'>();
    MyNFT.mint(recipient, 0);
    MyNFT.mint(caller, 1);

    MyNFT
}

fn setup_test_environment(name: felt252, symbol: felt252) -> (
    ContractAddress,
    IERC721SafeDispatcher,
){
     let caller = contract_address_const::<'caller'>();
    // Get the caller address.
    // Deploy the ERC20 contract.
    let erc721_address = deploy_erc721(name, symbol, caller);
    // Get an interface to interact with the ERC20 contract.
    let erc721 = IERC721SafeDispatcher{contract_address: erc721_address};

    // Prank the caller.
    start_prank(erc721_address, caller);

}


fn deploy_erc721(name: felt252, symbol: felt252, recipient: ContractAddress) -> ContractAddress {
    let class_hash = declare('ERC721');
    let mut constructor_calldata = array![];
    constructor_calldata.append(name);
    constructor_calldata.append(symbol);
    constructor_calldata.append(recipient.into());
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}