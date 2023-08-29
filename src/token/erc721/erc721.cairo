// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.7.0 (token/erc721/erc721.cairo)

use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TState> {
    /// Returns the name of the token.
    fn name(self: @TState) -> felt252;
    /// Returns the symbol of the token, usually a shorter version of the name.
    fn symbol(self: @TState) -> felt252;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn approve(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
}

#[starknet::interface]
trait IERC721Metadata<TState> {
    fn token_uri(self: @TState, token_id: u256) -> felt252;
    fn generate_token_uri(ref self: TState, token_id: u256) -> Span<felt252>;
}

#[starknet::contract]
mod ERC721 {
    use array::{SpanTrait, ArrayTrait};
    use traits::Into;
    use StarkBank::token::erc721::interface;
    use option::OptionTrait;
    use starknet::{ContractAddress, contract_address_const};
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use cairo_json::json_metadata::{JsonMetadata, JsonMetadataTrait, DisplayType};



    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _owners: LegacyMap<u256, ContractAddress>,
        _balances: LegacyMap<ContractAddress, u256>,
        _token_approvals: LegacyMap<u256, ContractAddress>,
        _operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        _token_uri: LegacyMap<u256, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        approved: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    #[derive::Drop]
    enum Color {
        Green: felt252,
        Orange: felt252,
        Red: felt252,
    }

    const RED: felt252 = '#CC0E0E';
    const GREEN: felt252 = '#0BB534';
    const ORANGE: felt252 = '#FF903F';

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        recipient: ContractAddress,
        token_id: u256
    ) {
        self.initializer(name, symbol);
        self._mint(recipient, token_id);
    }

    //
    // External
    //

    #[external(v0)]
    impl ERC721MetadataImpl of interface::IERC721Metadata<ContractState> {
        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_uri.read(token_id)
        }

        fn generate_token_uri(ref self: ContractState, token_id: u256) -> Span<felt252> {
            let mut uri: Array<felt252> = Default::default();
            uri.append('data:application/json,');

            let mut metadata: JsonMetadata = JsonMetadata {
            members: Default::default(), attributes: Default::default()
            };

            self._add_metadata_members(ref metadata);

            metadata.append_to_string(ref uri);

            uri.span()
        }
    }

    #[external(v0)]
    impl ERC721Impl of interface::IERC721<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), 'ERC721: invalid account');
            self._balances.read(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self._operator_approvals.read((owner, operator))
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || ERC721Impl::is_approved_for_all(@self, owner, caller),
                'ERC721: unauthorized caller'
            );
            self._approve(to, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(get_caller_address(), operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            self._transfer(from, to, token_id);
        }
    }

    #[generate_trait]
    impl UriHelper of UriHelperTrait {
        fn _compute_cr(ref self: ContractState) -> felt252 {
            '3.09'
        }

        fn _compute_collateral(ref self: ContractState) -> felt252 {
            '152.7'
        }

        fn _compute_color(ref self: ContractState) -> felt252 {
            let CR: u256 = self._compute_cr().into();

            if (CR <= 1) {
                RED
            } else if (CR <= 2) {
                ORANGE
            } else {
                GREEN
            }
        }

        fn _compute_starkName(ref self: ContractState) -> felt252 {
            '0xJustGus'
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name_: felt252, symbol_: felt252) {
            self._name.write(name_);
            self._symbol.write(symbol_);
        }

        fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self._owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
            }
        }

        fn _exists(self: @ContractState, token_id: u256) -> bool {
            !self._owners.read(token_id).is_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self._owner_of(token_id);
            let is_approved_for_all = ERC721Impl::is_approved_for_all(self, owner, spender);
            owner == spender
                || is_approved_for_all
                || spender == ERC721Impl::get_approved(self, token_id)
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);
            assert(owner != to, 'ERC721: approval to owner');

            self._token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        fn _set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, 'ERC721: self approval');
            self._operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner, operator, approved });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            assert(!self._exists(token_id), 'ERC721: token already minted');

            self._balances.write(to, self._balances.read(to) + 1);
            self._owners.write(token_id, to);

            self.emit(Transfer { from: Zeroable::zero(), to, token_id });
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            let owner = self._owner_of(token_id);
            assert(from == owner, 'ERC721: wrong sender');

            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            self._balances.write(from, self._balances.read(from) - 1);
            self._balances.write(to, self._balances.read(to) + 1);
            self._owners.write(token_id, to);

            self.emit(Transfer { from, to, token_id });
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = self._owner_of(token_id);

            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            self._balances.write(owner, self._balances.read(owner) - 1);
            self._owners.write(token_id, Zeroable::zero());

            self.emit(Transfer { from: owner, to: Zeroable::zero(), token_id });
        }

        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252){
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_uri.write(token_id, token_uri)
        }

        fn _upload_svg_onchain(ref self: ContractState)  -> Span<felt252>{

            let color: felt252 = self._compute_color();
            let CR: felt252 = self._compute_cr();
            let addr: felt252 = self._compute_starkName();
            let collateral: felt252 = self._compute_collateral();


            let mut arr: Array<felt252> = ArrayTrait::new();


            arr.append('<svg xmlns="http://www.w3.');
            arr.append('org/2000/svg" xmlns:xlink="ht');
            arr.append('tp://www.w3.org/1999/xlink" v');
            arr.append('ersion="1.1" viewBox="0 0 40');
            arr.append('0 400" preserveAspectRatio=');
            arr.append('"xMidYMid meet"> <style type=');
            arr.append('"text/css"><![CDATA[ text { f');
            arr.append('ont-family: monospace; font-s');
            arr.append('ize: 21px; } .h1 { font-size');
            arr.append(': 40px; font-weight: 600; } ]');
            arr.append(']></style> <rect width="400"');
            arr.append(' height="400" fill="');
            arr.append(color);
            arr.append('"/> <text class="h1" x="50" y');
            arr.append('="70">Your lending </text> <t');
            arr.append('ext class="h1" x="80" y="120');
            arr.append('">position:</text> <text x="2');
            arr.append('5%" y="210" style="font-size');
            arr.append(':10px; text-anchor: middle;">');
            arr.append('Health Factor: 3.09 </text> ');
            arr.append('<text x="25%" y="230" style="fo');
            arr.append('nt-size:10px; text-anchor: mi');
            arr.append('ddle;">Collateral: 155$ </text');
            arr.append('> <text x="75%" y="210" style=');
            arr.append('"font-size:10px; text-anchor:');
            arr.append(' middle;">Collateral Ratio: 0');
            arr.append('.32</text> <text x="75%" y="2');
            arr.append('30" style="font-size:10px; tex');
            arr.append('t-anchor: middle;">Liabilities');
            arr.append(': 40$</text> <text x="50%" y=');
            arr.append('"360" style="font-size:12px; t');
            arr.append('ext-anchor: middle;"> Your wa');
            arr.append('llet address: </text> <text x');
            arr.append('="50%" y="380" style="font-siz');
            arr.append('e:10px; text-anchor: middle;">');
            arr.append('0xF25c288A1FfE4b0a5B90C9cCCDD8E');
            arr.append('13Bc7c7E685282813F5f9f </text>');
            arr.append('</svg>');

            arr.span()
        }

        fn _add_metadata_members(ref self: ContractState, ref metadata: JsonMetadata){
            let mut name = ArrayTrait::<felt252>::new();
            name.append('dNFTzzz');

            let mut description = ArrayTrait::<felt252>::new();
            description.append('View in an interactive way your');
            description.append('borrowing positions');
            
            metadata.add_member('description', description.span());
            metadata.add_member('name',name.span());
            metadata.add_member('image', self._upload_svg_onchain());
        }

    }
}
// <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet">
//     <style type="text/css"><![CDATA[
//         text { font-family: monospace; font-size: 21px; }
//         .h1 { font-size: 40px; font-weight: 600; }
//     ]]></style>
//     <rect width="400" height="400" fill="#0BB534" />
//     <text class="h1" x="50" y="70">Your lending </text>
//     <text class="h1" x="80" y="120">position:</text>
//     <text x="25%" y="210" style="font-size:10px; text-anchor: middle;">Health Factor: 3.09 </text>
//       <text x="25%" y="230" style="font-size:10px; text-anchor: middle;">Collateral: 155$ </text>
//     <text x="75%" y="210" style="font-size:10px; text-anchor: middle;">Collateral Ratio: 0.32</text>
//       <text x="75%" y="230" style="font-size:10px; text-anchor: middle;">Liabilities: 40$</text>
//     <text x="50%" y="360" style="font-size:12px; text-anchor: middle;">
//         Your wallet address:
//     </text>
//     <text x="50%" y="380" style="font-size:10px; text-anchor: middle;">
//         0xF25c288A1FfE4b0a5B90C9cCCDD8E13Bc7c7E685282813F5f9f
//     </text>
// </svg>


// '<svg xmlns="http://www.w3.'
// 'org/2000/svg" xmlns:xlink="ht'
// 'tp://www.w3.org/1999/xlink" v'
// 'ersion="1.1" viewBox="0 0 40'
// '0 400" preserveAspectRatio='
// '"xMidYMid meet"> <style type='
// '"text/css"><![CDATA[ text { f'
// 'ont-family: monospace; font-s'
// 'ize: 21px; } .h1 { font-size'
// ': 40px; font-weight: 600; } ]'
// ']></style> <rect width="400"'
// ' height="400" fill="#0BB534"'
// '/> <text class="h1" x="50" y'
// '="70">Your lending </text> <t'
// 'ext class="h1" x="80" y="120'
// '">position:</text> <text x="2'
// '5%" y="210" style="font-size'
// ':10px; text-anchor: middle;">'
// 'Health Factor: 3.09 </text> '
// '<text x="25%" y="230" style="fo'
// 'nt-size:10px; text-anchor: mi'
// 'ddle;">Collateral: 155$ </text'
// '> <text x="75%" y="210" style='
// '"font-size:10px; text-anchor:'
// ' middle;">Collateral Ratio: 0'
// '.32</text> <text x="75%" y="2'
// '30" style="font-size:10px; tex'
// 't-anchor: middle;">Liabilities'
// ': 40$</text> <text x="50%" y='
// '"360" style="font-size:12px; t'
// 'ext-anchor: middle;"> Your wa'
// 'llet address: </text> <text x'
// '="50%" y="380" style="font-siz'
// 'e:10px; text-anchor: middle;">'
// '0xF25c288A1FfE4b0a5B90C9cCCDD8E'
// '13Bc7c7E685282813F5f9f </text>'
// '</svg>'


