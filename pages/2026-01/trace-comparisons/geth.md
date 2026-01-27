---
title: Geth
description: debug_traceTransaction quirks report for Geth
date: 2026-01-21T07:48:24Z
author: savid
tags:
  - trace
  - debug
  - evm
  - geth
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
</script>

<PageMeta
    date="2026-01-21T07:48:24Z"
    author="savid"
    tags={["trace", "debug", "evm", "geth"]}
/>

- **Total transactions analyzed**: 500
- **geth successful traces**: 500 (100%)

This report documents differences in `debug_traceTransaction` output from **geth** compared to the majority behavior of other clients (besu, erigon, nethermind, reth).

## Missing Keys

geth omits these keys that other clients include:

### `storage` (463,907 occurrences)

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

### `memory` (8,461 occurrences)

| Opcode | Count |
|--------|-------|
| PUSH1 | 4,526 |
| MSTORE | 2,017 |
| DUP1 | 233 |
| PUSH2 | 191 |
| JUMPI | 149 |
| CALLDATALOAD | 119 |
| JUMPDEST | 97 |
| PUSH0 | 84 |
| DUP2 | 82 |
| SHR | 82 |
| ADD | 73 |
| EQ | 65 |
| CALLDATACOPY | 59 |
| PUSH20 | 52 |
| XOR | 52 |

### `reason` (11 occurrences)

| Opcode | Count |
|--------|-------|
| REVERT | 11 |

## Extra Keys (Present When Others Omit)

geth includes these keys that other clients omit:

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

### `storage` (6,438 occurrences)

| Opcode | Count |
|--------|-------|
| SLOAD | 6,267 |
| SSTORE | 171 |

### `memory` (154 occurrences)

| Opcode | Count |
|--------|-------|
| POP | 25 |
| PUSH2 | 21 |
| PUSH1 | 12 |
| SWAP3 | 11 |
| JUMPI | 11 |
| JUMPDEST | 8 |
| DUP1 | 7 |
| SWAP4 | 7 |
| ISZERO | 7 |
| LT | 6 |
| DUP2 | 6 |
| EQ | 4 |
| RETURNDATASIZE | 3 |
| PUSH0 | 3 |
| DUP5 | 3 |

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

### Storage Format

How storage keys and values are formatted. Clients differ in zero-padding.

| Aspect | Style | Count |
|--------|-------|-------|
| Keys | 64-char padded (e.g., `0000...0000`) | 199 |
| Values | 64-char padded | 199 |

**Example 1** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Key | Value |
|--------|-----|-------|
| besu | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0` |
| erigon | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0000000000000000000000000000000000000000000000000000000000000000` |
| geth | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0000000000000000000000000000000000000000000000000000000000000000` |
| reth | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0000000000000000000000000000000000000000000000000000000000000000` |

**Example 2** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`):

| Client | Key | Value |
|--------|-----|-------|
| besu | `6d18c230d386c5b3168af2f8cee4ff8e42e8df554070485ae9d29e162b64ff96` | `963081` |
| erigon | `0000000000000000000000000000000000000000000000000000000000000001` | `0000000000000000000000004914f61d25e5c567143774b76edbf4d5109a8566` |
| geth | `0000000000000000000000000000000000000000000000000000000000000001` | `0000000000000000000000004914f61d25e5c567143774b76edbf4d5109a8566` |
| reth | `6d18c230d386c5b3168af2f8cee4ff8e42e8df554070485ae9d29e162b64ff96` | `0000000000000000000000000000000000000000000000000000000000963081` |

**Example 3** (block 24281427, tx `0x3ca0e49a00a58f59250ac5908be6516d6a98fe4dc5f8647060c2b937afff2513`):

| Client | Key | Value |
|--------|-----|-------|
| besu | `65e825459894c28caa3bf45c046bcb806478983a744f47c04782164e994daae2` | `11b333bba0493` |
| erigon | `0000000000000000000000000000000000000000000000000000000000000000` | `000000000000000000000000c6cde7c39eb2f0f0095f41570af89efc2c1ea828` |
| geth | `0000000000000000000000000000000000000000000000000000000000000000` | `000000000000000000000000c6cde7c39eb2f0f0095f41570af89efc2c1ea828` |
| reth | `65e825459894c28caa3bf45c046bcb806478983a744f47c04782164e994daae2` | `00000000000000000000000000000000000000000000000000011b333bba0493` |
