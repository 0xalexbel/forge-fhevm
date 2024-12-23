// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

/*
 * keccak256(bytes("ffhevm.wallet"))
 *     pk bytes32 : 0x36aef6ef9b2d2ea6233c0a4a9d24263befafdc501db4cc80703e9912c9a53358
 *     pk uint256 : 24734029502138379870110717996306894033782550968556396636283790010549514089304
 *     address : 0x568294c3043895f54d076Dd453345bAA2f35015e
 *
 *     0x48E78e61d109Cb7eCC557d929172ACb5d4FB2288
 *     0x7fBcC227F7859299706a6b36B5DFfcdA455D5aaa
 *     0x078B0Ae7c9eba7D2b582caA310776A8aB9e3029D
 *     0x0Edf8d23ca36336969976Ea049B454DF02c9B1b7
 *     0x097c7B03Cc559e130EE913fe1a5CAFe2A4560905
 *     0xbec497Eb40BA30d3832EA7a804b10b48BBBA2E58
 *     0xd13491D09CFa178C2da80894d4C0C33F754F75eA
 *     0x68FeB1Efac92198b3bdfb2b71dA4a7780Bb3c1eb
 *     0x06d866c8c8896371BDAF16e76dE525c1780BDE9b
 *     0x1d9b6c7653bc3f42d323F88a62a1a906cfC9E73c
 *     0xADdd82B7E695F0584Ae59fdDAc38d3466781084A
 *     0xFAEDaD5B967D66C577e7A45de96aE37313bDaad1
 *     0x8f2D7Ee2C9192dF255A3062494B1D4FF94839f3c
 *     0x5D271E3C0E82808484F11c9793f045C6D3A5b58E
 *     0x2144F01895841BD2b347d759e6324BFF4Af254c5
 *     0xe58eeaDefC861c3D29D0291e4fCdFb7280985b56
 *     0x82fd73d06DC554058A03D626aEd70Cf21bd7A345
 *     0x9d2e98F478B42F24A6F96f08aDac7664F747e5AE
 *     0x9F7795Eb5f1ebDA2182fA89bDc4B99AdDD9D4a14
 *     0x7BF4F22f1708Aa82D05F6B03c480c5807fF1D12f
 */

// Pk = keccak256(bytes("ffhevm.wallet"))
uint256 constant FFHEVM_PRECOMPILE_PK = 24734029502138379870110717996306894033782550968556396636283790010549514089304;
address constant FFHEVM_PRECOMPILE_ADDRESS = 0x568294c3043895f54d076Dd453345bAA2f35015e;

// Pk = keccak256(bytes("ffhevm.wallet"))
// Nonce = 0
uint64 constant FFHEVM_INPUT_PRECOMPILE_NONCE = 0;
address constant FFHEVM_INPUT_PRECOMPILE_ADDRESS = 0x48E78e61d109Cb7eCC557d929172ACb5d4FB2288;
// Nonce = 1
uint64 constant FFHEVM_GATEWAY_PRECOMPILE_NONCE = 1;
address constant FFHEVM_GATEWAY_PRECOMPILE_ADDRESS = 0x7fBcC227F7859299706a6b36B5DFfcdA455D5aaa;
// Nonce = 2
uint64 constant FFHEVM_REENCRYPT_PRECOMPILE_NONCE = 2;
address constant FFHEVM_REENCRYPT_PRECOMPILE_ADDRESS = 0x078B0Ae7c9eba7D2b582caA310776A8aB9e3029D;
