---
title: Precompile Usage on Mainnet
sidebar_position: 1
description: EVM precompile usage on Ethereum mainnet — modexp dominates, driven almost entirely by Aztec's ZK rollup proofs
date: 2026-03-12T00:00:00Z
author: samcm
tags:
  - precompiles
  - execution
  - modexp
  - zk-rollups
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // Chart 1: Precompile ranking - horizontal dual bar (calls vs gas)
    $: rankingCallsConfig = (() => {
        if (!precompile_ranking || precompile_ranking.length === 0 || precompile_ranking[0].precompile == null) return {};
        const sorted = [...precompile_ranking].sort((a, b) => Number(a.call_count) - Number(b.call_count));
        return {
            title: { text: 'Precompile Ranking by Call Count', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = sorted.find(r => r.precompile === d.name);
                    return `<b>${d.name}</b><br/>Calls: ${Number(d.value).toLocaleString()} (${row?.call_pct}%)<br/>Avg gas: ${Number(row?.avg_gas).toLocaleString()}`;
                }
            },
            grid: { left: 10, right: 30, bottom: 50, top: 50, containLabel: true },
            xAxis: {
                type: 'value',
                name: 'Call Count',
                nameLocation: 'center',
                nameGap: 30,
                axisLabel: { formatter: v => v >= 1e6 ? (v / 1e6).toFixed(0) + 'M' : v >= 1e3 ? (v / 1e3).toFixed(0) + 'K' : v }
            },
            yAxis: { type: 'category', data: sorted.map(d => d.precompile) },
            series: [{
                type: 'bar',
                data: sorted.map(d => ({
                    value: Number(d.call_count),
                    itemStyle: { color: d.precompile === 'modexp' ? '#dc2626' : '#2563eb' }
                })),
                barMaxWidth: 30,
                label: { show: true, position: 'right', fontSize: 9, formatter: p => sorted[p.dataIndex]?.call_pct + '%' }
            }]
        };
    })();

    $: rankingGasConfig = (() => {
        if (!precompile_ranking || precompile_ranking.length === 0 || precompile_ranking[0].precompile == null) return {};
        const sorted = [...precompile_ranking].sort((a, b) => Number(a.total_gas) - Number(b.total_gas));
        return {
            title: { text: 'Precompile Ranking by Gas Consumed', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = sorted.find(r => r.precompile === d.name);
                    return `<b>${d.name}</b><br/>Gas: ${Number(d.value).toLocaleString()} (${row?.gas_pct}%)<br/>Avg gas/call: ${Number(row?.avg_gas).toLocaleString()}`;
                }
            },
            grid: { left: 10, right: 30, bottom: 50, top: 50, containLabel: true },
            xAxis: {
                type: 'value',
                name: 'Total Gas',
                nameLocation: 'center',
                nameGap: 30,
                axisLabel: { formatter: v => v >= 1e9 ? (v / 1e9).toFixed(0) + 'B' : v >= 1e6 ? (v / 1e6).toFixed(0) + 'M' : v }
            },
            yAxis: { type: 'category', data: sorted.map(d => d.precompile) },
            series: [{
                type: 'bar',
                data: sorted.map(d => ({
                    value: Number(d.total_gas),
                    itemStyle: { color: d.precompile === 'modexp' ? '#dc2626' : '#2563eb' }
                })),
                barMaxWidth: 30,
                label: { show: true, position: 'right', fontSize: 9, formatter: p => sorted[p.dataIndex]?.gas_pct + '%' }
            }]
        };
    })();

    // Chart 2: Time series - stacked area by precompile
    $: timeSeriesConfig = (() => {
        if (!precompile_time_series || precompile_time_series.length === 0 || precompile_time_series[0].block_bucket == null) return {};
        const buckets = [...new Set(precompile_time_series.map(d => Number(d.block_bucket)))].sort((a, b) => a - b);
        const precompileOrder = ['modexp', 'ecrecover', 'identity', 'sha256', 'ecMul', 'ecAdd', 'ecPairing', 'point_eval', 'blake2f', 'ripemd160', 'bls12_g1add', 'bls12_g1mul', 'bls12_g1multiexp', 'bls12_g2add', 'bls12_g2mul', 'bls12_g2multiexp', 'bls12_pairing', 'bls12_map_fp_to_g1', 'bls12_map_fp2_to_g2', 'other'];
        const precompiles = precompileOrder.filter(p => precompile_time_series.some(d => d.precompile === p));
        const dataMap = {};
        precompile_time_series.forEach(d => {
            if (!dataMap[d.precompile]) dataMap[d.precompile] = {};
            dataMap[d.precompile][Number(d.block_bucket)] = Number(d.total_calls);
        });
        const colors = {
            'modexp': '#dc2626', 'ecrecover': '#2563eb', 'identity': '#16a34a',
            'sha256': '#9333ea', 'ecMul': '#06b6d4', 'ecAdd': '#ea580c',
            'ecPairing': '#be185d', 'point_eval': '#ca8a04',
            'blake2f': '#7c3aed', 'ripemd160': '#d97706',
            'bls12_g1add': '#059669', 'bls12_g1mul': '#0d9488', 'bls12_g1multiexp': '#0891b2',
            'bls12_g2add': '#4f46e5', 'bls12_g2mul': '#7c3aed', 'bls12_g2multiexp': '#a855f7',
            'bls12_pairing': '#db2777', 'bls12_map_fp_to_g1': '#e11d48', 'bls12_map_fp2_to_g2': '#f43f5e',
            'other': '#9ca3af'
        };
        return {
            title: { text: 'Precompile Calls Over Time (~1 day buckets)', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis' },
            legend: { data: precompiles, right: 10, orient: 'vertical', top: 'center', textStyle: { fontSize: 10 } },
            grid: { left: 80, right: 140, bottom: 80, top: 50 },
            xAxis: {
                type: 'category',
                data: buckets,
                axisLabel: { interval: 9, rotate: 45, fontSize: 9, formatter: v => Number(v).toLocaleString() },
                name: 'Block Number',
                nameLocation: 'center',
                nameGap: 60
            },
            yAxis: {
                type: 'value',
                name: 'Call Count',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90,
                axisLabel: { formatter: v => v >= 1e6 ? (v / 1e6).toFixed(1) + 'M' : v >= 1e3 ? (v / 1e3).toFixed(0) + 'K' : v }
            },
            series: precompiles.map(name => ({
                name,
                type: 'line',
                stack: 'total',
                areaStyle: { opacity: 0.4 },
                data: buckets.map(b => dataMap[name]?.[b] || 0),
                itemStyle: { color: colors[name] || '#999' },
                lineStyle: { color: colors[name] || '#999', width: 1 },
                symbol: 'none'
            }))
        };
    })();

    // Chart 2b: Gas over time - stacked area by precompile
    $: gasTimeSeriesConfig = (() => {
        if (!precompile_time_series || precompile_time_series.length === 0 || precompile_time_series[0].block_bucket == null) return {};
        const buckets = [...new Set(precompile_time_series.map(d => Number(d.block_bucket)))].sort((a, b) => a - b);
        const precompileOrder = ['modexp', 'ecrecover', 'point_eval', 'ecPairing', 'ecMul', 'identity', 'sha256', 'ecAdd', 'blake2f', 'ripemd160', 'bls12_g1add', 'bls12_g1mul', 'bls12_g1multiexp', 'bls12_g2add', 'bls12_g2mul', 'bls12_g2multiexp', 'bls12_pairing', 'bls12_map_fp_to_g1', 'bls12_map_fp2_to_g2', 'other'];
        const precompiles = precompileOrder.filter(p => precompile_time_series.some(d => d.precompile === p));
        const dataMap = {};
        precompile_time_series.forEach(d => {
            if (!dataMap[d.precompile]) dataMap[d.precompile] = {};
            dataMap[d.precompile][Number(d.block_bucket)] = Number(d.total_gas);
        });
        const colors = {
            'modexp': '#dc2626', 'ecrecover': '#2563eb', 'identity': '#16a34a',
            'sha256': '#9333ea', 'ecMul': '#06b6d4', 'ecAdd': '#ea580c',
            'ecPairing': '#be185d', 'point_eval': '#ca8a04',
            'blake2f': '#7c3aed', 'ripemd160': '#d97706',
            'bls12_g1add': '#059669', 'bls12_g1mul': '#0d9488', 'bls12_g1multiexp': '#0891b2',
            'bls12_g2add': '#4f46e5', 'bls12_g2mul': '#7c3aed', 'bls12_g2multiexp': '#a855f7',
            'bls12_pairing': '#db2777', 'bls12_map_fp_to_g1': '#e11d48', 'bls12_map_fp2_to_g2': '#f43f5e',
            'other': '#9ca3af'
        };
        return {
            title: { text: 'Precompile Gas Over Time (~1 day buckets)', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis' },
            legend: { data: precompiles, right: 10, orient: 'vertical', top: 'center', textStyle: { fontSize: 10 } },
            grid: { left: 80, right: 140, bottom: 80, top: 50 },
            xAxis: {
                type: 'category',
                data: buckets,
                axisLabel: { interval: 9, rotate: 45, fontSize: 9, formatter: v => Number(v).toLocaleString() },
                name: 'Block Number',
                nameLocation: 'center',
                nameGap: 60
            },
            yAxis: {
                type: 'value',
                name: 'Gas',
                nameLocation: 'center',
                nameGap: 60,
                nameRotate: 90,
                axisLabel: { formatter: v => v >= 1e9 ? (v / 1e9).toFixed(1) + 'B' : v >= 1e6 ? (v / 1e6).toFixed(0) + 'M' : v }
            },
            series: precompiles.map(name => ({
                name,
                type: 'line',
                stack: 'gas',
                areaStyle: { opacity: 0.4 },
                data: buckets.map(b => dataMap[name]?.[b] || 0),
                itemStyle: { color: colors[name] || '#999' },
                lineStyle: { color: colors[name] || '#999', width: 1 },
                symbol: 'none'
            }))
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

```sql precompile_ranking
select * from xatu_cbt.precompile_ranking
```

```sql precompile_time_series
select * from xatu_cbt.precompile_time_series
```

<Section type="question">

## Question

Which EVM precompiles consume the most gas on Ethereum mainnet, and who is driving that usage?

</Section>

<Section type="background">

## Background

The EVM has precompiled contracts at addresses `0x01` through `0x13`. These are native implementations of cryptographic and utility functions that would be too expensive to run as Solidity bytecode:

| Address | Name | Function |
|---------|------|----------|
| `0x01` | [ecrecover](./ecrecover) | ECDSA public key recovery |
| `0x02` | [sha256](./sha256) | SHA-256 hash |
| `0x03` | [ripemd160](./ripemd160) | RIPEMD-160 hash |
| `0x04` | [identity](./identity) | Data copy (returns input unchanged) |
| `0x05` | [modexp](./modexp) | Modular exponentiation |
| `0x06`–`0x08` | [BN128 ops](./bn128) | ecAdd, ecMul, ecPairing |
| `0x09` | [blake2f](./blake2f) | BLAKE2b compression function |
| `0x0a` | [point_eval](./point-eval) | KZG point evaluation (EIP-4844) |
| `0x0b`–`0x13` | [BLS12-381 ops](./bls12-381) | G1/G2 add, mul, multiexp, pairing, map-to-curve (EIP-2537, Pectra) |

Precompile gas pricing is a live debate. If a precompile is underpriced relative to its actual execution cost, attackers can stuff blocks with cheap-but-slow calls. But repricing has real consequences for every protocol that depends on that precompile.

We use the `int_transaction_call_frame` table, which records every internal call frame from transaction execution traces. Precompile calls show up as frames with `opcode_count = 0` (no EVM bytecode to run). The `gas` field tells us how much gas the call consumed, and for variable-cost precompiles like modexp, gas maps directly to input complexity.

**Data range**: blocks 24,120,001 to 24,546,241 (~426,000 blocks, approximately 59 days from late December 2025 to late February 2026).

</Section>

<Section type="investigation">

## Investigation

### Overall ranking

<SqlSource source="xatu_cbt" query="precompile_ranking" />

<ECharts config={rankingCallsConfig} height="400px" />

<ECharts config={rankingGasConfig} height="400px" />

modexp is #1 in both: 25% of all precompile calls, 38% of all gas. The gas ranking looks quite different from calls though. ecPairing jumps from 7th in calls to 4th in gas because each call costs ~129,000 gas (the most expensive per-call by far). ecMul is similar at 6,000 gas per call.

The cheap ones (identity at 27 gas, sha256 at 89 gas, ecAdd at 150 gas) get called a lot but barely register on total gas.

Each precompile has its own page (linked in the table above) with caller breakdowns and gas distributions.

### Calls over time

<SqlSource source="xatu_cbt" query="precompile_time_series" />

<ECharts config={timeSeriesConfig} height="500px" />

Pretty flat. Total calls hover around 1.1-1.2M per day-bucket, with modexp (red) as the largest band, followed by ecrecover (blue) and identity (green). No sudden shifts or spikes over the 59-day window.

### Gas over time

Same data, but showing gas instead of calls. The picture shifts — modexp and ecrecover dominate gas even though the call counts look more evenly spread.

<ECharts config={gasTimeSeriesConfig} height="500px" />

</Section>

<Section type="takeaways">

## Takeaways

- Over ~426,000 blocks (~59 days), 70.4 million precompile calls consumed 188.7 billion gas
- modexp is #1 by both call count (25.3%) and gas (37.7%), driven almost entirely by Aztec's ZK rollup ([details](./modexp))
- The gas ranking differs from the call ranking — expensive-per-call precompiles like ecPairing punch above their weight
- Usage is flat over the analysis period, no sudden shifts
- BLS12-381 precompiles (Pectra) have 63 calls total — g2multiexp accounts for most of them ([details](./bls12-381))

</Section>
