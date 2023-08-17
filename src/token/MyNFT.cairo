use StarkBank::token::ERC721;


#[starknet::interface]
trait MyNFT<TContractState> {}

#[starknet::contract]
mod MyNFT {
    use StarkBank::token::ERC721;


    #[external(v0)]
    impl InternalFunctions of InternalFunctionsTrait {
        fn mint(self: @ContractState, to: ContractAddress, token_id: u256) {
            ERC721._mint(self, to, token_id);
        }
    }
}

