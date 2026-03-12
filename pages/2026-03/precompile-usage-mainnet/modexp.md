---
title: modexp
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: gasDistConfig = (() => {
        if (!modexp_gas_dist || modexp_gas_dist.length === 0 || modexp_gas_dist[0].gas_value == null) return {};
        return {
            title: { text: 'Modexp Gas Value Distribution (Complexity Proxy)', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = modexp_gas_dist.find(r => String(r.gas_value) === d.name);
                    return `Gas: ${d.name}<br/>Calls: ${Number(d.value).toLocaleString()} (${row?.pct}%)`;
                }
            },
            grid: { left: 10, right: 15, bottom: 70, top: 50, containLabel: true },
            xAxis: {
                type: 'category',
                data: modexp_gas_dist.map(d => String(d.gas_value)),
                axisLabel: { rotate: 45, fontSize: 10 },
                name: 'Gas Value',
                nameLocation: 'center',
                nameGap: 50
            },
            yAxis: {
                type: 'value',
                name: 'Call Count',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90,
                axisLabel: { formatter: v => v >= 1e6 ? (v / 1e6).toFixed(1) + 'M' : v >= 1e3 ? (v / 1e3).toFixed(0) + 'K' : v }
            },
            series: [{
                type: 'bar',
                data: modexp_gas_dist.map(d => ({
                    value: Number(d.call_count),
                    itemStyle: { color: Number(d.gas_value) === 4048 ? '#dc2626' : '#2563eb' }
                })),
                barMaxWidth: 60
            }]
        };
    })();

    $: callersConfig = (() => {
        if (!modexp_callers || modexp_callers.length === 0 || modexp_callers[0].calling_contract == null) return {};
        const sorted = [...modexp_callers].sort((a, b) => Number(a.modexp_calls) - Number(b.modexp_calls));
        const truncate = (addr) => addr.slice(0, 10) + '...' + addr.slice(-4);
        return {
            title: { text: 'Top Contracts Calling Modexp', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = sorted.find(r => truncate(r.calling_contract) === d.name);
                    return `<b>${row?.calling_contract}</b><br/>Modexp calls: ${Number(d.value).toLocaleString()}<br/>Avg gas: ${Number(row?.avg_gas).toLocaleString()}`;
                }
            },
            grid: { left: 10, right: 30, bottom: 50, top: 50, containLabel: true },
            xAxis: {
                type: 'value',
                name: 'Modexp Calls',
                nameLocation: 'center',
                nameGap: 30,
                axisLabel: { formatter: v => v >= 1e6 ? (v / 1e6).toFixed(1) + 'M' : v >= 1e3 ? (v / 1e3).toFixed(0) + 'K' : v }
            },
            yAxis: {
                type: 'category',
                data: sorted.map(d => truncate(d.calling_contract)),
                axisLabel: { fontSize: 9, fontFamily: 'monospace' }
            },
            series: [{
                type: 'bar',
                data: sorted.map((d, i) => ({
                    value: Number(d.modexp_calls),
                    itemStyle: { color: i === sorted.length - 1 ? '#dc2626' : '#2563eb' }
                })),
                barMaxWidth: 30,
                label: { show: true, position: 'right', fontSize: 9, formatter: p => Number(p.value).toLocaleString() }
            }]
        };
    })();

    $: perTxConfig = (() => {
        if (!modexp_per_tx || modexp_per_tx.length === 0 || modexp_per_tx[0].modexp_count == null) return {};
        const sorted = [...modexp_per_tx].sort((a, b) => Number(a.modexp_count) - Number(b.modexp_count));
        return {
            title: { text: 'Modexp Calls Per Transaction', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = sorted.find(r => String(r.modexp_count) === d.name);
                    return `${d.name} modexp calls/tx<br/>Transactions: ${Number(d.value).toLocaleString()} (${row?.pct}%)`;
                }
            },
            grid: { left: 10, right: 15, bottom: 70, top: 50, containLabel: true },
            xAxis: {
                type: 'category',
                data: sorted.map(d => String(d.modexp_count)),
                axisLabel: { rotate: 45, fontSize: 10 },
                name: 'Modexp Calls in Transaction',
                nameLocation: 'center',
                nameGap: 50
            },
            yAxis: {
                type: 'value',
                name: 'Transaction Count',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90,
                axisLabel: { formatter: v => v >= 1e3 ? (v / 1e3).toFixed(1) + 'K' : v }
            },
            series: [{
                type: 'bar',
                data: sorted.map(d => ({
                    value: Number(d.tx_count),
                    itemStyle: { color: Number(d.modexp_count) === 277 ? '#dc2626' : '#2563eb' }
                })),
                barMaxWidth: 60
            }]
        };
    })();
</script>

<PageMeta
    date="2026-03-12T00:00:00Z"
    authors={["samcm", "mattevans"]}
    tags={["precompiles", "execution", "modexp", "zk-rollups"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-29T00:00:00Z"
    endTime="2026-02-26T23:59:59Z"
/>

```sql modexp_gas_dist
select * from xatu_cbt.precompile_modexp_gas_dist
```

```sql modexp_callers
select * from xatu_cbt.precompile_modexp_callers
```

```sql modexp_per_tx
select * from xatu_cbt.precompile_modexp_per_tx
```

<Section type="question">

## Question

Who is driving modexp usage and what does their call pattern look like?

</Section>

<Section type="background">

## Background

**modexp** (`0x05`) computes modular exponentiation: `base^exp mod modulus`. Gas cost scales with the size of the inputs (base length, exponent length, modulus length), making it a variable-cost precompile where gas per call is a direct proxy for input complexity.

modexp is the #1 precompile by both call count (25.3%) and gas (37.7%). Over the analysis period it was called 17.8 million times, consuming 71.2 billion gas.

</Section>

<Section type="investigation">

## Investigation

### Gas distribution

Is modexp usage spread across many different input sizes, or is it one thing?

<SqlSource source="xatu_cbt" query="precompile_modexp_gas_dist" />

<ECharts config={gasDistConfig} height="400px" />

It's one thing. 98% of all modexp calls consume exactly 4,048 gas. Same input parameters, millions of times. The next most common value (500 gas) accounts for just 1.4%.

### Top callers

> **Note:** The callers data below covers a smaller window (~6,000 blocks) because the self-join query needed to resolve parent contracts is too expensive to run over the full range. The gas distribution above uses the full 426K-block range.

<SqlSource source="xatu_cbt" query="precompile_modexp_callers" />

<ECharts config={callersConfig} height="400px" />

One contract accounts for 94% of all modexp calls: `0x77e3ba096355510e0e9f60d292010b42d662d2b5`. It's a ZK proof verifier with 364,000 opcodes that calls modexp as part of proof verification.

Tracing up from the verifier to the top-level transaction:

```text
depth 0: 0x603b...ca12 — "Aztec: Ignition Chain L2 Rollup" (Etherscan-verified)
  └ depth 1: 0x1e0a...c1a4 — Implementation contract (DELEGATECALL)
      ├ depth 2: 24x ecrecover — Signature verification
      ├ depth 2: 1x point_eval — Blob KZG verification
      └ depth 2: 0x77e3...d2b5 — ZK verifier (STATICCALL)
          ├ depth 3: 277x modexp (gas=4048 each)
          ├ depth 3: 65x ecAdd
          ├ depth 3: 65x ecMul
          └ depth 3: 1x ecPairing
```

It's Aztec Network's ZK rollup, submitting epoch root proofs to mainnet. Each proof verification transaction calls the verifier, which does exactly 277 modexp operations as part of the proof math, plus BN128 curve operations (ecAdd, ecMul, ecPairing).

### Calls per transaction

Grouping modexp calls by transaction confirms the pattern.

<SqlSource source="xatu_cbt" query="precompile_modexp_per_tx" />

<ECharts config={perTxConfig} height="400px" />

The spike at 277 says it all. The vast majority of transactions containing modexp calls make exactly 277 of them. These are Aztec epoch proof submissions, about 1,100 per day.

</Section>

<Section type="takeaways">

## Takeaways

- modexp is #1 by both call count (25.3%) and gas (37.7%)
- 98% of calls hit the same gas value (4,048) — this isn't diverse usage, it's one protocol's verification loop
- Aztec Network's ZK rollup accounts for ~94% of all modexp usage
- Each epoch proof does exactly 277 modexp calls at 4,048 gas each
- Aztec submits ~1,100 proof transactions per day, burning roughly 1.2 billion modexp gas daily
- Repricing modexp (e.g., EIP-7883) would land almost entirely on ZK rollup verification costs

</Section>
