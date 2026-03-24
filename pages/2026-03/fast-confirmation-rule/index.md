---
title: Fast Confirmation Rule on Mainnet
sidebar_position: 2
description: Would the Fast Confirmation Rule work on Ethereum mainnet? Measuring confirmation rates across adversarial assumptions and checking safety against real reorgs.
date: 2026-03-24T00:00:00Z
author: samcm
tags:
  - consensus
  - fast-confirmation
  - attestations
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // ============================================================
    // Pre-computed FCR simulation data
    // ============================================================

    // CDF of confirmation times by city (March 2026, stable period)
    // X axis: milliseconds after slot start
    const cdfCityX = [7800, 7850, 7900, 7950, 8000, 8050, 8100, 8150, 8200, 8250, 8300, 8350, 8400, 8450, 8500, 8550, 8600, 8650, 8700, 8750, 8800, 8850, 8900, 8950, 9000, 9050, 9100, 9150, 9200, 9250, 9300, 9350, 9400, 9450, 9500, 9550, 9600, 9650, 9700, 9750];
    const cdfCity_helsinki = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 30.95, 83.51, 91.7, 93.21, 93.67, 93.74, 93.86, 94.05, 94.42, 94.79, 95.21, 95.55, 95.87, 96.27, 96.56, 96.74, 96.82, 96.84, 96.86, 96.87, 96.93, 96.93, 96.96, 96.97, 96.99, 96.99, 96.99, 97.01, 97.01, 97.01, 97.01, 97.01, 97.01, 97.01];
    const cdfCity_amsterdam = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 12.63, 87.37, 94.62, 96.77, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04, 97.04];
    const cdfCity_sydney = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.45, 66.8, 89.07, 94.33, 96.04, 96.85, 96.94, 96.99, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03, 97.03];
    const cdfCity_bengaluru = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 17.89, 49.58, 71.67, 81.45, 86.86, 89.75, 92.36, 93.66, 95.34, 96.18, 96.64, 96.74, 96.92, 96.92, 96.92, 96.92, 97.02, 97.02, 97.11, 97.11, 97.2, 97.2, 97.2, 97.2, 97.2, 97.2, 97.2, 97.2, 97.2, 97.2, 97.2, 97.2];
    const cdfCity_santaclara = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 45.97, 68.44, 76.77, 80.43, 82.53, 84.89, 86.56, 88.12, 89.19, 90.86, 91.77, 92.37, 93.33, 93.76, 94.25, 94.52, 94.89, 95.16, 95.38, 95.48, 95.59, 95.65, 95.97, 96.02, 96.02, 96.02, 96.02, 96.02, 96.02, 96.13, 96.13, 96.18];


    // ============================================================
    // Chart configs
    // ============================================================

    const cityColors = {
        'Helsinki': '#2563eb',
        'Amsterdam': '#16a34a',
        'Bengaluru': '#ea580c',
        'Santa Clara': '#9333ea',
        'Sydney': '#dc2626'
    };

    const thresholdColors = {
        95: '#2563eb',
        90: '#7c3aed',
        85: '#ea580c',
        80: '#9ca3af'
    };

    // Chart 1: Daily confirmation rate at multiple thresholds
    $: confirmConfig = (() => {
        if (!fcr_head_vote_daily || fcr_head_vote_daily.length === 0 || fcr_head_vote_daily[0].date == null) return {};
        const dates = fcr_head_vote_daily.map(d => d.date);
        return {
            title: { text: 'Daily Slot Confirmation Rate by Threshold', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    let html = `<b>${params[0].axisValue}</b><br/>`;
                    params.forEach(p => { html += `${p.marker} ${p.seriesName}: ${p.value}%<br/>`; });
                    return html;
                }
            },
            legend: { data: ['\u2265 95% (\u03B2=0.25)', '\u2265 90%', '\u2265 85%', '\u2265 80%'], bottom: 0 },
            grid: { left: 60, right: 30, bottom: 60, top: 50 },
            xAxis: {
                type: 'category',
                data: dates,
                name: 'Date',
                nameLocation: 'center',
                nameGap: 40,
                axisLabel: { interval: 14, rotate: 45, fontSize: 10 }
            },
            yAxis: {
                type: 'value',
                name: 'Slots Confirmed (%)',
                nameLocation: 'center',
                nameGap: 40,
                nameRotate: 90,
                min: 70,
                max: 100
            },
            series: [
                { name: '\u2265 95% (\u03B2=0.25)', type: 'line', data: fcr_head_vote_daily.map(d => Number(d.pct_95)), symbol: 'none', lineStyle: { color: thresholdColors[95], width: 2.5 }, itemStyle: { color: thresholdColors[95] } },
                { name: '\u2265 90%', type: 'line', data: fcr_head_vote_daily.map(d => Number(d.pct_90)), symbol: 'none', lineStyle: { color: thresholdColors[90], width: 1.5 }, itemStyle: { color: thresholdColors[90] } },
                { name: '\u2265 85%', type: 'line', data: fcr_head_vote_daily.map(d => Number(d.pct_85)), symbol: 'none', lineStyle: { color: thresholdColors[85], width: 1.5 }, itemStyle: { color: thresholdColors[85] } },
                { name: '\u2265 80%', type: 'line', data: fcr_head_vote_daily.map(d => Number(d.pct_80)), symbol: 'none', lineStyle: { color: thresholdColors[80], width: 1, type: 'dashed' }, itemStyle: { color: thresholdColors[80] } }
            ]
        };
    })();

    // Chart 2: CDF of confirmation times by city
    $: cdfCityConfig = {
        title: { text: 'FCR Confirmation Time CDF by City', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: {
            trigger: 'axis',
            formatter: (params) => {
                let html = `<b>${params[0].axisValue}ms</b><br/>`;
                params.forEach(p => { html += `${p.marker} ${p.seriesName}: ${p.value}%<br/>`; });
                return html;
            }
        },
        legend: { data: ['Helsinki', 'Amsterdam', 'Bengaluru', 'Santa Clara', 'Sydney'], bottom: 0 },
        grid: { left: 70, right: 30, bottom: 80, top: 50 },
        xAxis: {
            type: 'category',
            data: cdfCityX.map(String),
            name: 'Time After Slot Start (ms)',
            nameLocation: 'center',
            nameGap: 40,
            axisLabel: { interval: 3, rotate: 0, fontSize: 10 }
        },
        yAxis: {
            type: 'value',
            name: 'Cumulative % of Slots Confirmed',
            nameLocation: 'center',
            nameGap: 50,
            nameRotate: 90,
            min: 0,
            max: 100
        },
        series: [
            { name: 'Helsinki', type: 'line', data: cdfCity_helsinki, symbol: 'none', lineStyle: { color: cityColors['Helsinki'], width: 2 }, itemStyle: { color: cityColors['Helsinki'] } },
            { name: 'Amsterdam', type: 'line', data: cdfCity_amsterdam, symbol: 'none', lineStyle: { color: cityColors['Amsterdam'], width: 2 }, itemStyle: { color: cityColors['Amsterdam'] } },
            { name: 'Bengaluru', type: 'line', data: cdfCity_bengaluru, symbol: 'none', lineStyle: { color: cityColors['Bengaluru'], width: 2 }, itemStyle: { color: cityColors['Bengaluru'] } },
            { name: 'Santa Clara', type: 'line', data: cdfCity_santaclara, symbol: 'none', lineStyle: { color: cityColors['Santa Clara'], width: 2 }, itemStyle: { color: cityColors['Santa Clara'] } },
            { name: 'Sydney', type: 'line', data: cdfCity_sydney, symbol: 'none', lineStyle: { color: cityColors['Sydney'], width: 2 }, itemStyle: { color: cityColors['Sydney'] } }
        ]
    };


</script>

<PageMeta
    date="2026-03-24T00:00:00Z"
    author="samcm"
    tags={["consensus", "fast-confirmation", "attestations"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-11-07T00:00:00Z"
    endTime="2026-03-17T23:59:59Z"
/>

```sql fcr_head_vote_daily
select * from xatu_cbt.fcr_head_vote_daily
```

```sql fcr_reorg_daily
select * from xatu_cbt.fcr_reorg_daily
```

```sql fcr_participation_daily
select * from xatu_cbt.fcr_participation_daily
```

<Section type="question">

## Question

Would the Fast Confirmation Rule work on Ethereum mainnet?

</Section>

<Section type="background">

## Background

The [Fast Confirmation Rule](https://github.com/ethereum/consensus-specs/pull/4747) (FCR) is a way for consensus clients to locally confirm blocks within seconds of the attestation deadline, rather than waiting ~13 minutes for FFG finality. No hard fork needed, it's a client-side check.

The full algorithm operates on the fork choice store: it starts from a safe checkpoint, computes LMD-GHOST scores using each validator's vote and the committee shuffling for the current and previous epochs, discounts proposer boost, and iteratively advances a `confirmed_root` through the canonical chain. A block is confirmed when its support is strong enough that no adversary (up to `β` fraction of stake) could cause a reorg. If a block doesn't get enough support from its own slot's committee, it can still confirm as attestations from subsequent slots accumulate.

</Section>

<Section type="investigation">

## Investigation

<div style="display: flex; gap: 0.75rem; padding: 0.875rem 1rem; background: #fef9ee; border: 1px solid #f0ddb8; border-radius: 6px; font-size: 0.9rem; line-height: 1.5; color: #7a5c1f; margin-bottom: 1.5rem;">
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#b8860b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink: 0; margin-top: 2px;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
<span>All results here are estimates. Rather than replaying the full FCR algorithm (which evaluates the entire fork choice tree), we use per-slot head vote ratios as a proxy. The real algorithm computes a dynamic safety threshold based on committee weights across multiple slots, proposer boost, equivocations, and empty slot discounts. In the simplest case (block confirmed within its own slot, `CONFIRMATION_BYZANTINE_THRESHOLD = 25`), this simplifies to roughly 95% of the slot's committee voting for the head. We use 95% as our proxy threshold. We also use finalized attestation data rather than real-time observations, so attestation arrival timing, propagation delays, and local node views are not captured.</span>
</div>

### How many slots would confirm?

*1,074,543 slots from Nov 7 2025 to Mar 17 2026 (131 days). Source: `fct_attestation_correctness_canonical` on xatu-cbt.*

Per slot, we check what fraction of the committee voted for the head block (`votes_head / votes_max`). If it clears the threshold, that slot would've been fast confirmed.

<SqlSource source="xatu_cbt" query="fcr_head_vote_daily" />

<ECharts config={confirmConfig} height="450px" />

At the 95% threshold, **96.9% of slots would fast confirm**. The worst day was December 4 during Fusaka-related network disruption, but even then 80% of slots still cleared the bar. Drop to a 90% threshold and the overall rate hits 98.4%.

| Threshold | Overall | Worst Day (Dec 4) |
|-----------|---------|-------------------|
| `>= 95%` (`β = 0.25`) | **96.9%** | 80.4% |
| `>= 90%` | 98.4% | 95.1% |
| `>= 85%` | 98.8% | 97.9% |
| `>= 80%` | 99.1% | 99.0% |

The ~3% that miss the 95% threshold are slots with late blocks, missed proposals, or low participation.

### Would any reorged block be confirmed?

*1,900 orphaned blocks from Nov 7 2025 to Mar 17 2026. Source: `fct_block_proposer FINAL` joined with `int_attestation_attested_canonical` on xatu-cbt.*

For every orphaned block, we check how much of the committee actually voted for it by matching each validator's `beacon_block_root` vote against the orphaned block's root.

**No.** None came close:

| Metric | Value |
|--------|-------|
| Orphaned blocks checked | 1,900 |
| Would confirm at `>= 95%` | 0 |
| Would confirm at `>= 80%` | 0 |
| Would confirm at `>= 50%` | 0 |
| Max support any orphan received | 47.8% |
| Average support | 2.1% |
| Median support | 0.4% |
| Not seen by committee at all | 20% |

Reorged blocks are blocks the committee never saw. The median orphan had 0.4% support. FCR wouldn't touch any of them.

### How fast would blocks confirm?

*372 slots sampled from Mar 3-17 2026, observed by 46 sentry nodes across 5 cities. Source: `libp2p_gossipsub_beacon_attestation` and `libp2p_gossipsub_aggregate_and_proof` on the xatu cluster.*

For each slot, we decode aggregation bitfields from gossipsub messages and track cumulative unique validator support over time to find when the 95% threshold is crossed.

<ECharts config={cdfCityConfig} height="450px" />

In this sample, 97% of slots confirm with a median time of **8,127ms** after slot start, about 4.1 seconds after the attestation deadline. Geographic spread is tight: Helsinki confirms at ~8.1s, Sydney at ~8.25s, less than 200ms apart.

Note that this data only derives attestations from _aggregates_. By default, nodes would also observe 2/64 of the committee via unaggregated attestations, resulting in faster confirmations. Nodes that are manually subscribed to all subnets would most likely confirm even faster.

</Section>

<Section type="takeaways">

## Takeaways

- **96.9% of slots would fast confirm** at the 95% threshold across 131 days and ~1M slots, hitting 97%+ on most days
- **Zero reorged blocks would be confirmed**: the highest support any orphaned block received was 47.8%, with a median of 0.4%
- **Blocks confirm ~4 seconds after the attestation deadline** in a 372-slot sample, with under 200ms variation across 5 cities

</Section>
