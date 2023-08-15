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

use StarkBank::token::ERC20::{IERC721Dispatcher, IERC721DispatcherTrait};

#[test]
fn nft_is_mintable(){
    
}