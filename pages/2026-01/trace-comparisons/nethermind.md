---
title: Nethermind
description: debug_traceTransaction quirks report for Nethermind
date: 2026-01-21T07:48:24Z
author: savid
tags:
  - trace
  - debug
  - evm
  - nethermind
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
</script>

<PageMeta
    date="2026-01-21T07:48:24Z"
    author="savid"
    tags={["trace", "debug", "evm", "nethermind"]}
/>

- **Total transactions analyzed**: 500
- **nethermind successful traces**: 500 (100%)

This report documents differences in `debug_traceTransaction` output from **nethermind** compared to the majority behavior of other clients (besu, geth, erigon, reth).

## Missing Keys

nethermind omits these keys that other clients include:

### `refund` (763,508 occurrences)

| Opcode | Count |
|--------|-------|
| PUSH1 | 83,102 |
| PUSH2 | 77,946 |
| JUMPDEST | 48,460 |
| POP | 44,501 |
| JUMPI | 38,709 |
| SWAP1 | 36,813 |
| DUP2 | 33,659 |
| DUP1 | 31,262 |
| ADD | 30,505 |
| JUMP | 26,377 |
| DUP3 | 22,811 |
| MSTORE | 21,059 |
| ISZERO | 21,033 |
| MLOAD | 20,467 |
| AND | 18,759 |

### `returnData` (385,340 occurrences)

| Opcode | Count |
|--------|-------|
| PUSH2 | 41,005 |
| PUSH1 | 38,349 |
| POP | 28,335 |
| JUMPDEST | 24,199 |
| DUP2 | 19,470 |
| SWAP1 | 18,588 |
| ADD | 18,379 |
| JUMPI | 16,923 |
| MLOAD | 15,668 |
| DUP3 | 13,714 |
| JUMP | 13,567 |
| DUP1 | 12,977 |
| MSTORE | 11,234 |
| ISZERO | 11,177 |
| SWAP2 | 9,529 |

### `reason` (11 occurrences)

| Opcode | Count |
|--------|-------|
| REVERT | 11 |

## Extra Keys (Present When Others Omit)

nethermind includes these keys that other clients omit:

### `storage` (470,345 occurrences)

| Opcode | Count |
|--------|-------|
| PUSH1 | 52,711 |
| PUSH2 | 43,254 |
| POP | 32,613 |
| JUMPDEST | 28,478 |
| SWAP1 | 24,708 |
| DUP2 | 21,551 |
| ADD | 18,977 |
| JUMPI | 17,880 |
| MLOAD | 16,535 |
| DUP3 | 16,257 |
| JUMP | 15,519 |
| DUP1 | 15,215 |
| MSTORE | 14,375 |
| ISZERO | 13,769 |
| AND | 13,172 |

### `memory` (8,615 occurrences)

| Opcode | Count |
|--------|-------|
| PUSH1 | 4,538 |
| MSTORE | 2,017 |
| DUP1 | 240 |
| PUSH2 | 212 |
| JUMPI | 160 |
| CALLDATALOAD | 119 |
| JUMPDEST | 105 |
| DUP2 | 88 |
| PUSH0 | 87 |
| SHR | 83 |
| ADD | 76 |
| EQ | 69 |
| CALLDATACOPY | 59 |
| PUSH20 | 53 |
| PUSH4 | 52 |

## Value Mismatches

nethermind returns different values for these keys:

### `storage` (1,673 occurrences)


**Example 1** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 884):
- **Difference**: missing keys: {'ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431'}

| Client | Value |
|--------|-------|
| nethermind | `{}` |
| Majority (erigon, reth, geth) | `{"ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0000000000000000000000000000000000000000000000000000000000000000"}` |

**Example 2** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 993):
- **Difference**: missing keys: {'ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431', '6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df'}

| Client | Value |
|--------|-------|
| nethermind | `{}` |
| Majority (erigon, reth, geth) | `{"6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df": "0000000000000000000000000000000000000000000000000ffa37c8fc87d417", "ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0000000000000000000000000000000000000000000000000000000000000000"}` |

**Example 3** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 1028):
- **Difference**: missing keys: {'ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431', '6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df', '833e8a6ac5920f2827d5f3263f2ef0f1f9c1191f2f72ae2e3c18b4e8e9cf98b8'}

| Client | Value |
|--------|-------|
| nethermind | `{}` |
| Majority (erigon, reth, geth) | `{"6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df": "0000000000000000000000000000000000000000000000000ffa37c8fc87d417", "833e8a6ac5920f2827d5f3263f2ef0f1f9c1191f2f72ae2e3c18b4e8e9cf98b8": "0000000000000000000000000000000000000000000000000f43fc2c04ee0000", "ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0000000000000000000000000000000000000000000000000000000000000000"}` |

## Top-Level `gas` Differences

nethermind reports different gas values at the top level:
- **Occurrences**: 3

**Example 1** (block 24281427, tx 0x30f3ade72365691d12f1060528afceefdca23c35e8f4689b7e45704e1a3c9e98):
- **nethermind**: `0`
- **Majority** (erigon, reth, geth): `226504`

**Example 2** (block 24281427, tx 0xb243519321267570bf16051695da7c426ea646aefa6a1a52a7e33e5c6a463908):
- **nethermind**: `0`
- **Majority** (erigon, geth, reth, besu): `24439`

**Example 3** (block 24281427, tx 0x664d5705f6e4716fafc9258417f2b80eea42ff40d00d047c36321cc3223ec793):
- **nethermind**: `0`
- **Majority** (erigon, besu, reth, geth): `156906`

## Format Quirks (Not Bugs)

These are formatting differences that don't affect trace correctness:

### returnValue Encoding

How empty return values are represented. These are semantically equivalent.

| Format | Count |
|--------|-------|
| `empty_as_0x` | 424 |
| `with_0x` | 74 |

**Example 1** (block 24281427, tx `0xbe3839523703cc914573c2a304367bff26fd6d08738389fc8d2bf857cdf3391c`):

| Client | Value |
|--------|-------|
| besu | `(empty)` |
| erigon | `0x` |
| geth | `0x` |
| nethermind | `0x` |
| reth | `0x` |

**Example 2** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `00000000000000000000000000000000000000000000000000...` |
| erigon | `0x000000000000000000000000000000000000000000000000...` |
| geth | `0x000000000000000000000000000000000000000000000000...` |
| nethermind | `0x000000000000000000000000000000000000000000000000...` |
| reth | `0x000000000000000000000000000000000000000000000000...` |

**Example 3** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`):

| Client | Value |
|--------|-------|
| besu | `00000000000000000000000000000000000000000000000000...` |
| erigon | `0x000000000000000000000000000000000000000000000000...` |
| geth | `0x000000000000000000000000000000000000000000000000...` |
| nethermind | `0x000000000000000000000000000000000000000000000000...` |
| reth | `0x000000000000000000000000000000000000000000000000...` |

### Memory Format

How memory words are formatted in structLogs.

| Format | Count |
|--------|-------|
| `64char_no_prefix` | 212 |

**Example 1** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `0x0` |
| erigon | `0000000000000000000000000000000000000000000000000000000000000000` |
| geth | `0000000000000000000000000000000000000000000000000000000000000000` |
| nethermind | `0000000000000000000000000000000000000000000000000000000000000000` |
| reth | `0000000000000000000000000000000000000000000000000000000000000000` |

**Example 2** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`):

| Client | Value |
|--------|-------|
| besu | `0x0` |
| erigon | `0000000000000000000000000000000000000000000000000000000000000000` |
| geth | `0000000000000000000000000000000000000000000000000000000000000000` |
| nethermind | `0000000000000000000000000000000000000000000000000000000000000000` |
| reth | `0000000000000000000000000000000000000000000000000000000000000000` |

**Example 3** (block 24281427, tx `0x3ca0e49a00a58f59250ac5908be6516d6a98fe4dc5f8647060c2b937afff2513`):

| Client | Value |
|--------|-------|
| besu | `0x0` |
| erigon | `0000000000000000000000000000000000000000000000000000000000000000` |
| geth | `0000000000000000000000000000000000000000000000000000000000000000` |
| nethermind | `0000000000000000000000000000000000000000000000000000000000000000` |
| reth | `0000000000000000000000000000000000000000000000000000000000000000` |

### Optional Fields

Fields this client includes that others may omit.

#### `error` (1,524,536 occurrences)

Includes `error: null` on every step (others omit when no error)

**Example 1** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: null` |
| reth | `missing` |

**Example 2** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: null` |
| reth | `missing` |

**Example 3** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: null` |
| reth | `missing` |

#### `storage` (1,052,519 occurrences)

Includes `storage: {}` on every step (others omit when empty)

**Example 1** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: {}` |
| reth | `missing` |

**Example 2** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: {}` |
| reth | `missing` |

**Example 3** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: {}` |
| reth | `missing` |
