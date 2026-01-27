---
title: Ethereum Client Trace Comparisons
sidebar_position: 6
description: Comparing debug_traceTransaction outputs across Ethereum clients
date: 2026-01-21T07:48:24Z
author: savid
tags:
  - trace
  - debug
  - evm
  - clients
  - geth
  - besu
  - reth
  - nethermind
  - erigon
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
</script>

<PageMeta
    date="2026-01-21T07:48:24Z"
    author="savid"
    tags={["trace", "debug", "evm", "clients", "geth", "besu", "reth", "nethermind", "erigon"]}
/>

This report compares `debug_traceTransaction` outputs across Ethereum execution clients to identify behavioral differences and formatting quirks.

> **Source**: This analysis was generated using [ethereum-trace-compare](https://github.com/Savid/ethereum-trace-compare)

## Overview

- **Total transactions**: 501
- **Skipped (client errors)**: 1
- **Analyzed**: 500
- **Clients**: besu, erigon, geth, nethermind, reth

---

## Difference Types Found

These are semantic differences detected in trace outputs. High counts indicate systematic differences in how clients report EVM execution.

| Type | Count | Description |
|------|-------|-------------|
| missing_key | 1,627,819 | Field present in some clients but not others |
| value_mismatch | 782,075 | Same field has different values |
| type_mismatch | 6,211 | Same field has different types |
| top_level_mismatch | 61 | Top-level trace fields differ |
| structlog_count_mismatch | 30 | Different number of structLog entries |

---

## Client Quirk Summary

This table shows where each client differs from the majority behavior. Lower numbers indicate better conformance.

| Client | Missing Keys | Extra Keys | Type Mismatches | Value Mismatches | Gas Diffs | ReturnValue Diffs |
|--------|--------------|------------|-----------------|------------------|-----------|-------------------|
| besu | 1,159,759 | 468,060 | 6,211 | 782,069 | 57 | 2 |
| erigon | 849,258 | 778,561 | 0 | 0 | 0 | 0 |
| geth | 472,379 | 1,155,440 | 0 | 0 | 0 | 0 |
| nethermind | 1,148,859 | 478,960 | 0 | 1,673 | 3 | 0 |
| reth | 979,808 | 648,011 | 0 | 1,993 | 0 | 0 |

---

## Per-Client Reports

Detailed reports for each client:

- [BESU](/2026-01/trace-comparisons/besu)
- [ERIGON](/2026-01/trace-comparisons/erigon)
- [GETH](/2026-01/trace-comparisons/geth)
- [NETHERMIND](/2026-01/trace-comparisons/nethermind)
- [RETH](/2026-01/trace-comparisons/reth)

---

## Format Quirks (Not Bugs)

These are formatting differences that don't affect trace correctness. The comparison tool normalizes these before semantic comparison.

### Return Value Encoding

How empty return values are represented. These are semantically equivalent.

| Client | Format | Count |
|--------|--------|-------|
| besu | `empty_as_empty` | 424 |
| besu | `no_0x` | 74 |
| erigon | `empty_as_0x` | 424 |
| erigon | `with_0x` | 74 |
| geth | `empty_as_0x` | 424 |
| geth | `with_0x` | 74 |
| nethermind | `empty_as_0x` | 424 |
| nethermind | `with_0x` | 74 |
| reth | `empty_as_0x` | 424 |
| reth | `with_0x` | 74 |

**Example** (block 24281427, tx `0xbe3839523703cc914573c2a304367bff26fd6d08738389fc8d2bf857cdf3391c`):

| Client | Value |
|--------|-------|
| besu | `(empty)` |
| erigon | `0x` |
| geth | `0x` |
| nethermind | `0x` |
| reth | `0x` |

### Memory Format

How memory words are formatted in structLogs.

| Client | Format | Count |
|--------|--------|-------|
| besu | `short_hex_with_0x` | 212 |
| erigon | `64char_no_prefix` | 212 |
| geth | `64char_no_prefix` | 212 |
| nethermind | `64char_no_prefix` | 212 |
| reth | `64char_no_prefix` | 212 |

**Example** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `0x0` |
| erigon | `0000000000000000000000000000000000000000000000000000000000000000` |
| geth | `0000000000000000000000000000000000000000000000000000000000000000` |
| nethermind | `0000000000000000000000000000000000000000000000000000000000000000` |
| reth | `0000000000000000000000000000000000000000000000000000000000000000` |

### Storage Format

How storage keys and values are formatted. Clients differ in zero-padding.

| Client | Keys | Values | Observations |
|--------|------|--------|-------------|
| besu | compact (39), 64-char (160) | compact (189), 64-char (10) | 199 txs |
| erigon | 64-char (199) | 64-char (199) | 199 txs |
| geth | 64-char (199) | 64-char (199) | 199 txs |
| reth | 64-char (199) | 64-char (199) | 199 txs |

**Example** (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Key | Value |
|--------|-----|-------|
| besu | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0` |
| erigon | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0000000000000000000000000000000000000000000000000000000000000000` |
| geth | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0000000000000000000000000000000000000000000000000000000000000000` |
| reth | `ef7498a2a84dafd941a59743b477cd1cfda22d923c58854eac2728d8ec554431` | `0000000000000000000000000000000000000000000000000000000000000000` |

### Optional Fields

Fields some clients include that others may omit.

| Client | Field | Count | Description |
|--------|-------|-------|-------------|
| besu | `structLog_for_simple_transfer` | 288 | Emits structLog for simple ETH transfers (others emit 0 entries) |
| nethermind | `error` | 1,524,536 | Includes `error: null` on every step |
| nethermind | `storage` | 1,052,519 | Includes `storage: {}` on every step |
| reth | `returnData` | 1,139,197 | Includes `returnData` field on every step |

**`error` example:**

*Example* (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: null` |
| reth | `missing` |

**`returnData` example:**

*Example* (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `missing` |
| reth | `present: '0x'` |

**`storage` example:**

*Example* (block 24281427, tx `0x584b891391ad58c565ea1bc9933b2f9b098e34d693ac8d77c465ba951ac2373a`):

| Client | Value |
|--------|-------|
| besu | `missing` |
| erigon | `missing` |
| geth | `missing` |
| nethermind | `present: {}` |
| reth | `missing` |

**`structLog_for_simple_transfer` example:**

*Example* (block 24281427, tx `0xbe3839523703cc914573c2a304367bff26fd6d08738389fc8d2bf857cdf3391c`):

| Client | Value |
|--------|-------|
| besu | `1 structLog entries` |
| erigon | `0 structLog entries` |
| geth | `0 structLog entries` |
| nethermind | `0 structLog entries` |
| reth | `0 structLog entries` |


# AI Analysis of Client Differences

# Ethereum Client `debug_traceTransaction` Analysis

## Executive Summary

Across 501 transactions, there are **2.4M+ differences** detected, but the vast majority are formatting variations rather than semantic bugs. The data reveals **three distinct categories**:

1. **Format-only differences** (cosmetic, no semantic impact)
2. **Field presence differences** (when/whether optional fields appear)
3. **Potential semantic differences** (actual behavioral divergence)

---

## 1. Key Behavioral Differences by Client

### Besu
| Issue | Severity | Details |
|-------|----------|---------|
| **Type mismatches** | **High** | `stack`: returns `bytes_array` vs others' `list`; `op`: returns `string` vs `hex_string`; `error`: returns `list` vs `string` |
| **Value mismatches** | **High** | 782,069 mismatches across `memory`, `storage`, `gasCost`, `gas`, `stack`, `pc`, `op`, `depth` |
| **Return value discrepancy** | **High** | 2 transactions return empty string instead of actual revert data (e.g., "Min return not reached" error lost) |
| **Extra structLog entries** | **Medium** | Adds 1 structLog entry for simple ETH transfers (288 cases) where others return 0 |
| **Gas differences** | **Medium** | 57 transactions with different gas values |

### Geth
| Issue | Severity | Details |
|-------|----------|---------|
| **Clean trace output** | N/A | Zero value mismatches, zero type mismatches |
| **Consistent behavior** | N/A | No structlog count mismatches, no gas differences |

### Erigon
| Issue | Severity | Details |
|-------|----------|---------|
| **Clean trace output** | N/A | Zero value mismatches, zero type mismatches |
| **Consistent with Geth** | N/A | Field presence/absence aligns with Geth |

### Nethermind
| Issue | Severity | Details |
|-------|----------|---------|
| **Storage value mismatches** | **Medium** | 1,673 storage value differences |
| **Gas differences** | **Medium** | 3 transactions with different gas values |
| **Extra empty fields** | **Low** | Includes `storage: {}` and `error: null` on every step (1M+ extra fields) |

### Reth
| Issue | Severity | Details |
|-------|----------|---------|
| **Value mismatches** | **Medium** | 1,993 mismatches in `storage`, `memory`, `gasCost` |
| **Extra returnData field** | **Low** | Includes `returnData: '0x'` on every step (1.1M extra fields) |

---

## 2. Separating Semantic Differences from Format Noise

### Format-Only (Safe to Normalize)

| Field | Variation | Clients |
|-------|-----------|---------|
| **returnValue encoding** | `""` vs `"0x"` for empty | Besu uses `""`, others use `"0x"` |
| **returnValue prefix** | With/without `0x` | Besu omits `0x` prefix |
| **memory format** | `"0x0"` vs 64-char padded | Besu uses short hex, others use zero-padded |
| **storage values** | Short vs 64-char padded | Besu uses minimal encoding (`"0"` vs `"00...00"`) |
| **storage keys** | Occasional short keys | Besu sometimes uses 63-char keys |

### Actual Semantic Differences

| Issue | Evidence | Affected Client(s) |
|-------|----------|-------------------|
| **Lost revert reason** | Besu returns `''` when others return ABI-encoded error | Besu |
| **Type representation** | `stack` as bytes vs list fundamentally changes parsing | Besu |
| **structLog for transfers** | 1 entry vs 0 for simple ETH transfers changes trace structure | Besu |
| **Storage state divergence** | Different storage key/value pairs at same execution point | Nethermind, Reth |
| **Gas accounting** | 60 total gas differences across Besu (57), Nethermind (3) | Besu, Nethermind |

---

## 3. Patterns Suggesting Bugs or Spec Violations

### [BUG] Besu: Return Data Loss
```
client_value: ''
majority_value: '0x08c379a0...4d696e2072657475726e206e6f74207265616368656400...'
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                            "Min return not reached" (ABI-encoded error)
```
**Impact**: Debugging tools lose revert reasons, making troubleshooting significantly harder.

### [BUG] Besu: Inconsistent Type Serialization
- `stack`: `bytes_array` instead of `list` - breaks standard JSON array iteration
- `op`: `string` instead of `hex_string` - inconsistent with other hex fields
- `error`: `list` instead of `string` - unexpected structure for error messages

### [BUG] Besu: Phantom structLog for Transfers
Simple ETH transfers (no contract code) produce 1 structLog entry in Besu, 0 in all others. This could indicate:
- Besu traces the implicit "stop" at empty code
- Others skip tracing entirely for EOA-to-EOA transfers

### [WARNING] Storage Reporting Point Divergence
The `storage` field shows massive differences in *which opcode* reports storage changes:
- **Geth/Erigon**: Report storage on `SLOAD`/`SSTORE` only
- **Besu**: Missing storage on `SLOAD`/`SSTORE`, but reports on unrelated opcodes (PUSH, DUP, etc.)
- **Nethermind/Reth**: Report storage on many non-storage opcodes

This suggests different interpretations of "when to snapshot storage state."

### [WARNING] Refund Counter Reporting
- **Geth/Erigon/Reth**: Include `refund` field throughout execution
- **Besu/Nethermind**: Missing `refund` on most opcodes

---

## 4. What Each Client Does (Without Assuming Reference)

### Storage Field Timing
| Client | Reports storage on SLOAD/SSTORE | Reports storage on other opcodes |
|--------|--------------------------------|----------------------------------|
| Geth | No | Yes (after state changes) |
| Erigon | Yes | No |
| Besu | No | Yes (on many opcodes) |
| Nethermind | Yes | Yes (always includes `{}`) |
| Reth | Yes | Yes |

### Memory Initialization Reporting
| Client | Reports memory on MSTORE/CALLDATACOPY | Reports memory on PUSH/stack ops |
|--------|--------------------------------------|----------------------------------|
| Geth | Yes | No |
| Erigon | Yes | Yes |
| Besu | Yes (different) | No |
| Nethermind | Yes | Yes |
| Reth | Yes | Yes |

### Refund Counter Availability
| Client | Includes refund field |
|--------|----------------------|
| Geth | Yes |
| Erigon | Yes |
| Besu | No |
| Nethermind | No |
| Reth | Partial (different values) |

---

## 5. Notable Quirks by Client

### Besu
- **Most divergent client** with 782K+ value mismatches
- Uses compact encoding (no zero-padding) - saves bytes but breaks simple string comparison
- Missing `0x` prefix on hex values in several places
- Returns empty revert data (data loss bug)
- Adds trace entries for EOA transfers
- Different type representations break API compatibility

### Geth
- **Cleanest output** - zero semantic mismatches in this dataset
- De facto reference for field presence patterns
- Consistent 64-char zero-padded hex encoding

### Erigon
- **Closest to Geth** in behavior
- Identical field presence/absence patterns
- Same encoding conventions

### Nethermind
- **Verbose output** - includes `storage: {}` and `error: null` even when empty
- 1,673 storage value differences suggest different snapshot timing
- 3 gas calculation differences worth investigating

### Reth
- **Extra returnData** field on every step (1.1M occurrences)
- Different refund counter behavior vs majority
- 1,993 value differences in storage/memory/gasCost
- Storage changes reported at slightly different execution points

---

## Recommendations

1. **For Besu team**: Investigate return data loss (high severity); consider aligning type serialization with majority

2. **For tooling developers**: Normalize these formats before comparison:
   - Strip/add `0x` prefix
   - Zero-pad hex values to expected length
   - Treat `""` and `"0x"` as equivalent for empty data

3. **For spec authors**: Clarify:
   - When storage field should be populated
   - Whether refund is required/optional
   - Expected behavior for EOA-to-EOA transfer traces
   - Canonical encoding for empty values
