---
title: Besu
description: debug_traceTransaction quirks report for Besu
date: 2026-01-21T07:48:24Z
author: savid
tags:
  - trace
  - debug
  - evm
  - besu
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
</script>

<PageMeta
    date="2026-01-21T07:48:24Z"
    author="savid"
    tags={["trace", "debug", "evm", "besu"]}
/>

- **Total transactions analyzed**: 500
- **besu successful traces**: 500 (100%)

This report documents differences in `debug_traceTransaction` output from **besu** compared to the majority behavior of other clients (geth, erigon, nethermind, reth).

## Missing Keys

besu omits these keys that other clients include:

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

### `memory` (6,451 occurrences)

| Opcode | Count |
|--------|-------|
| PUSH1 | 4,411 |
| DUP1 | 240 |
| PUSH2 | 212 |
| JUMPI | 160 |
| CALLDATALOAD | 119 |
| JUMPDEST | 105 |
| MSTORE | 90 |
| DUP2 | 88 |
| PUSH0 | 87 |
| SHR | 83 |
| ADD | 76 |
| EQ | 69 |
| PUSH20 | 53 |
| PUSH4 | 52 |
| XOR | 52 |

### `storage` (4,460 occurrences)

| Opcode | Count |
|--------|-------|
| SLOAD | 4,406 |
| SSTORE | 54 |

## Extra Keys (Present When Others Omit)

besu includes these keys that other clients omit:

### `storage` (465,885 occurrences)

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

### `memory` (2,164 occurrences)

| Opcode | Count |
|--------|-------|
| MSTORE | 1,927 |
| PUSH1 | 127 |
| CALLDATACOPY | 59 |
| CODECOPY | 51 |

### `reason` (11 occurrences)

| Opcode | Count |
|--------|-------|
| REVERT | 11 |

## Type Mismatches

besu returns different types for these keys:

### `stack` (801 occurrences)


**Example 1** (block 24281427, tx 0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa, index 40621):
- **besu**: `bytes_array`
- **Others**: `list`

**Example 2** (block 24281427, tx 0x8fc0a88209d79a978783a3ac07cc93ff0fc2649e4e09faa75127f697d8b00274, index 112):
- **besu**: `bytes_array`
- **Others**: `list`

**Example 3** (block 24281427, tx 0xedf8e4ea8875423f44e41d518671562fbdfc57ca32b5dffd047c35ff78b80344, index 13918):
- **besu**: `bytes_array`
- **Others**: `list`

### `op` (5,409 occurrences)


**Example 1** (block 24281427, tx 0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa, index 40670):
- **besu**: `string`
- **Others**: `hex_string`

**Example 2** (block 24281427, tx 0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa, index 40671):
- **besu**: `hex_string`
- **Others**: `string`

**Example 3** (block 24281427, tx 0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa, index 40673):
- **besu**: `string`
- **Others**: `hex_string`

### `error` (1 occurrences)


**Example 1** (block 24281427, tx 0x664d5705f6e4716fafc9258417f2b80eea42ff40d00d047c36321cc3223ec793, index 7168):
- **besu**: `list`
- **Others**: `string`

## Value Mismatches

besu returns different values for these keys:

### `gas` (516,808 occurrences)


**Example 1** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 2810):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `539701` |
| Majority (erigon, nethermind, reth, geth) | `536901` |

**Example 2** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 2811):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `539698` |
| Majority (erigon, nethermind, reth, geth) | `536898` |

**Example 3** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 2812):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `539695` |
| Majority (erigon, nethermind, reth, geth) | `536895` |

### `pc` (69,677 occurrences)


**Example 1** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 40621):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `0` |
| Majority (erigon, nethermind, reth, geth) | `14116` |

**Example 2** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 40622):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `14116` |
| Majority (erigon, nethermind, reth, geth) | `14117` |

**Example 3** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 40623):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `14117` |
| Majority (erigon, nethermind, reth, geth) | `14118` |

### `stack` (65,771 occurrences)


**Example 1** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 3029):
- **Difference**: item[48] differs: `0x8cefb` vs `0x8c40b`

| Client | Value |
|--------|-------|
| besu | `['0xf2c42696', '0x15a', '0x19afd', '0x24', '0x104', '0x3', '0x0', '0xf2b', '0x19afd', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x24', '0x104', '0x3', '0x58b271b364b9', '0x697082d8', '0x80', '0x320', '0x0', '0x0', '0x0', '0x63f', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0x0', '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x0', '0x214b', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x2', '0x81b320', '0x1', '0x3314', '0x80', '0x1', '0x81b320', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x484', '0x20', '0x0', '0x24', '0x484', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x8cefb']` |
| Majority (erigon, nethermind, reth, geth) | `['0xf2c42696', '0x15a', '0x19afd', '0x24', '0x104', '0x3', '0x0', '0xf2b', '0x19afd', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x24', '0x104', '0x3', '0x58b271b364b9', '0x697082d8', '0x80', '0x320', '0x0', '0x0', '0x0', '0x63f', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0x0', '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x0', '0x214b', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x2', '0x81b320', '0x1', '0x3314', '0x80', '0x1', '0x81b320', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x484', '0x20', '0x0', '0x24', '0x484', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x8c40b']` |

**Example 2** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 3151):
- **Difference**: item[9] differs: `0x8a8db` vs `0x89e17`

| Client | Value |
|--------|-------|
| besu | `['0x70a08231', '0x75', '0x211', '0x43506849d7c04f9138d1a2050bbf3a0c054402dd', '0x0', '0x0', '0x24', '0x0', '0x43506849d7c04f9138d1a2050bbf3a0c054402dd', '0x8a8db']` |
| Majority (erigon, nethermind, reth, geth) | `['0x70a08231', '0x75', '0x211', '0x43506849d7c04f9138d1a2050bbf3a0c054402dd', '0x0', '0x0', '0x24', '0x0', '0x43506849d7c04f9138d1a2050bbf3a0c054402dd', '0x89e17']` |

**Example 3** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 3389):
- **Difference**: item[59] differs: `0x8c7ee` vs `0x8bcfe`

| Client | Value |
|--------|-------|
| besu | `['0xf2c42696', '0x15a', '0x19afd', '0x24', '0x104', '0x3', '0x0', '0xf2b', '0x19afd', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x24', '0x104', '0x3', '0x58b271b364b9', '0x697082d8', '0x80', '0x320', '0x0', '0x0', '0x0', '0x63f', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0x0', '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x0', '0x214b', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x2', '0x81b320', '0x1', '0x3314', '0x80', '0x1', '0x81b320', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x1499d', '0x0', '0x0', '0x81b320', '0x1499d', '0x2cffed5d56eb6a17662756ca0fdf350e732c9818', '0x32fd', '0x1499d', '0x2cffed5d56eb6a17662756ca0fdf350e732c9818', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x4a8', '0x20', '0x0', '0x44', '0x4a8', '0x0', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x8c7ee']` |
| Majority (erigon, nethermind, reth, geth) | `['0xf2c42696', '0x15a', '0x19afd', '0x24', '0x104', '0x3', '0x0', '0xf2b', '0x19afd', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x24', '0x104', '0x3', '0x58b271b364b9', '0x697082d8', '0x80', '0x320', '0x0', '0x0', '0x0', '0x63f', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0x0', '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x0', '0x214b', '0x80', '0x60b14aeb5ef438e37c594427c9e51a04da933f77', '0x963080', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x2', '0x81b320', '0x1', '0x3314', '0x80', '0x1', '0x81b320', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x1499d', '0x0', '0x0', '0x81b320', '0x1499d', '0x2cffed5d56eb6a17662756ca0fdf350e732c9818', '0x32fd', '0x1499d', '0x2cffed5d56eb6a17662756ca0fdf350e732c9818', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x4a8', '0x20', '0x0', '0x44', '0x4a8', '0x0', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', '0x8bcfe']` |

### `op` (59,126 occurrences)


**Example 1** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 40621):
- **Difference**: string length differs (4 vs 5)

| Client | Value |
|--------|-------|
| besu | `STOP` |
| Majority (erigon, nethermind, reth, geth) | `SWAP3` |

**Example 2** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 40622):
- **Difference**: string length differs (5 vs 3)

| Client | Value |
|--------|-------|
| besu | `SWAP3` |
| Majority (erigon, nethermind, reth, geth) | `POP` |

**Example 3** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 40625):
- **Difference**: string length differs (3 vs 14)

| Client | Value |
|--------|-------|
| besu | `POP` |
| Majority (erigon, nethermind, reth, geth) | `RETURNDATASIZE` |

### `memory` (36,671 occurrences)


**Example 1** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 511):
- **Difference**: list length differs (6 vs 3)

| Client | Value |
|--------|-------|
| besu | `['0x0', '0x0', '0x80', '0x0', '0x0', '0x23b872dd00000000000000000000000000000000000000000000000000000000']` |
| Majority (erigon, nethermind, reth, geth) | `['0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000080']` |

**Example 2** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 523):
- **Difference**: list length differs (7 vs 6)

| Client | Value |
|--------|-------|
| besu | `['0x0', '0x0', '0x80', '0x0', '0x0', '0x23b872dd0000000000000000000000001880bbe18f847e579f512b7a398ab65c', '0x7510d7f800000000000000000000000000000000000000000000000000000000']` |
| Majority (erigon, nethermind, reth, geth) | `['0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000080', '0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000000', '23b872dd00000000000000000000000000000000000000000000000000000000']` |

**Example 3** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 531):
- **Difference**: list length differs (8 vs 7)

| Client | Value |
|--------|-------|
| besu | `['0x0', '0x0', '0x80', '0x0', '0x0', '0x23b872dd0000000000000000000000001880bbe18f847e579f512b7a398ab65c', '0x7510d7f8000000000000000000000000b92fe925dc43a0ecde6c8b1a2709c170', '0xec4fff4f00000000000000000000000000000000000000000000000000000000']` |
| Majority (erigon, nethermind, reth, geth) | `['0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000080', '0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000000', '23b872dd0000000000000000000000001880bbe18f847e579f512b7a398ab65c', '7510d7f800000000000000000000000000000000000000000000000000000000']` |

### `gasCost` (30,766 occurrences)


**Example 1** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 2809):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `100` |
| Majority (erigon, nethermind, reth, geth) | `2900` |

**Example 2** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 3029):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `568257` |
| Majority (erigon, nethermind, reth, geth) | `565501` |

**Example 3** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 3151):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `558650` |
| Majority (erigon, nethermind, reth, geth) | `555937` |

### `storage` (1,668 occurrences)


**Example 1** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 884):
- **Difference**: key `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` differs

| Client | Value |
|--------|-------|
| besu | `{"ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0"}` |
| Majority (erigon, reth, geth) | `{"ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0000000000000000000000000000000000000000000000000000000000000000"}` |

**Example 2** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 993):
- **Difference**: key `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` differs

| Client | Value |
|--------|-------|
| besu | `{"6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df": "ffa37c8fc87d417", "ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0"}` |
| Majority (erigon, reth, geth) | `{"6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df": "0000000000000000000000000000000000000000000000000ffa37c8fc87d417", "ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0000000000000000000000000000000000000000000000000000000000000000"}` |

**Example 3** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`, index 1028):
- **Difference**: key `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` differs

| Client | Value |
|--------|-------|
| besu | `{"6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df": "ffa37c8fc87d417", "833e8a6ac5920f2827d5f3263f2ef0f1f9c1191f2f72ae2e3c18b4e8e9cf98b8": "f43fc2c04ee0000", "ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0"}` |
| Majority (erigon, reth, geth) | `{"6a23b495c397abd2ae3dbcbcb685b0dde8201a017a43b2855ca4bfc72f7820df": "0000000000000000000000000000000000000000000000000ffa37c8fc87d417", "833e8a6ac5920f2827d5f3263f2ef0f1f9c1191f2f72ae2e3c18b4e8e9cf98b8": "0000000000000000000000000000000000000000000000000f43fc2c04ee0000", "ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431": "0000000000000000000000000000000000000000000000000000000000000000"}` |

### `depth` (1,582 occurrences)


**Example 1** (block 24281427, tx `0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa`, index 40621):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `2` |
| Majority (erigon, nethermind, reth, geth) | `1` |

**Example 2** (block 24281427, tx `0x8fc0a88209d79a978783a3ac07cc93ff0fc2649e4e09faa75127f697d8b00274`, index 112):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `2` |
| Majority (erigon, reth, geth, nethermind) | `1` |

**Example 3** (block 24281427, tx `0xedf8e4ea8875423f44e41d518671562fbdfc57ca32b5dffd047c35ff78b80344`, index 13918):
- **Difference**: values differ

| Client | Value |
|--------|-------|
| besu | `4` |
| Majority (erigon, nethermind, reth, geth) | `3` |

## Top-Level `gas` Differences

besu reports different gas values at the top level:
- **Occurrences**: 57

**Example 1** (block 24281427, tx 0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa):
- **besu**: `464116`
- **Majority** (erigon, nethermind, reth, geth): `490996`

**Example 2** (block 24281427, tx 0x3ca0e49a00a58f59250ac5908be6516d6a98fe4dc5f8647060c2b937afff2513):
- **besu**: `43309`
- **Majority** (erigon, reth, geth, nethermind): `46109`

**Example 3** (block 24281427, tx 0x7bf095066454135a52cec000f448944affa6f138aafa5d0704a1eefb7e3c9b05):
- **besu**: `178151`
- **Majority** (erigon, nethermind, reth, geth): `189351`

... and 54 more

## Top-Level `returnValue` Differences

besu formats returnValue differently:
- **Occurrences**: 2

**Example 1** (block 24281427, tx 0x30f3ade72365691d12f1060528afceefdca23c35e8f4689b7e45704e1a3c9e98):
- **besu**: `''`
- **Majority** (erigon, nethermind, reth, geth): `'0x08c379a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000164d696e2072657475726e206e6f74207265616368656400000000000000000000'`

**Example 2** (block 24281427, tx 0xb243519321267570bf16051695da7c426ea646aefa6a1a52a7e33e5c6a463908):
- **besu**: `''`
- **Majority** (erigon, geth, reth, nethermind): `'0x559895a3'`

## StructLog Count Mismatches

besu returned a different number of structLog entries 30 times.

**Example 1** (block 24281427, tx 0x223536b6f7dd0dad73bcba405dfa2fde23888773d98e284086e650013b239bfa):
- **besu**: 41,064 entries
- **Majority** (erigon, nethermind, reth, geth): 41,063 entries
- All clients: besu=41,064, erigon=41,063, geth=41,063, nethermind=41,063, reth=41,063

**Example 2** (block 24281427, tx 0x8fc0a88209d79a978783a3ac07cc93ff0fc2649e4e09faa75127f697d8b00274):
- **besu**: 136 entries
- **Majority** (erigon, reth, geth, nethermind): 135 entries
- All clients: besu=136, erigon=135, geth=135, nethermind=135, reth=135

**Example 3** (block 24281427, tx 0xedf8e4ea8875423f44e41d518671562fbdfc57ca32b5dffd047c35ff78b80344):
- **besu**: 17,560 entries
- **Majority** (erigon, nethermind, reth, geth): 17,558 entries
- All clients: besu=17,560, erigon=17,558, geth=17,558, nethermind=17,558, reth=17,558

**Example 4** (block 24281427, tx 0xc707d1f60921bd50b3cda4fc17792b04a2f17eff1b75f9f6b318e223446ff712):
- **besu**: 1,516 entries
- **Majority** (erigon, reth, geth, nethermind): 1,510 entries
- All clients: besu=1,516, erigon=1,510, geth=1,510, nethermind=1,510, reth=1,510

**Example 5** (block 24281427, tx 0x09a72819ad114bcf47f5df13de81d2895947a46049d42671183ca675e33c3047):
- **besu**: 14,275 entries
- **Majority** (erigon, nethermind, reth, geth): 14,274 entries
- All clients: besu=14,275, erigon=14,274, geth=14,274, nethermind=14,274, reth=14,274

... and 25 more occurrences

## Format Quirks (Not Bugs)

These are formatting differences that don't affect trace correctness:

### returnValue Encoding

How empty return values are represented. These are semantically equivalent.

| Format | Count |
|--------|-------|
| `empty_as_empty` | 424 |
| `no_0x` | 74 |

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
| `short_hex_with_0x` | 212 |

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
| Keys | Compact (e.g., `0`, `1`) | 39 |
| Keys | 64-char padded (e.g., `0000...0000`) | 160 |
| Values | Compact (e.g., `0x1`, `abc`) | 189 |
| Values | 64-char padded | 10 |

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

### Optional Fields

Fields this client includes that others may omit.

#### `structLog_for_simple_transfer` (288 occurrences)

Emits a structLog entry for simple ETH transfers (no EVM execution), while other clients emit 0 entries

**Example 1** (block 24281427, tx `0xbe3839523703cc914573c2a304367bff26fd6d08738389fc8d2bf857cdf3391c`):

| Client | Value |
|--------|-------|
| besu | `1 structLog entries` |
| erigon | `0 structLog entries` |
| geth | `0 structLog entries` |
| nethermind | `0 structLog entries` |
| reth | `0 structLog entries` |

**Example 2** (block 24281427, tx `0xd16650ad8ef9171a2afc07ccb5b945a140bae05d89cf7aeb6683aa37b15e8267`):

| Client | Value |
|--------|-------|
| besu | `1 structLog entries` |
| erigon | `0 structLog entries` |
| geth | `0 structLog entries` |
| nethermind | `0 structLog entries` |
| reth | `0 structLog entries` |

**Example 3** (block 24281427, tx `0x6ee0323325ec89035d0d51b5fe8e61179906d1aa70776d387b3f65f917d3075d`):

| Client | Value |
|--------|-------|
| besu | `1 structLog entries` |
| erigon | `0 structLog entries` |
| geth | `0 structLog entries` |
| nethermind | `0 structLog entries` |
| reth | `0 structLog entries` |
