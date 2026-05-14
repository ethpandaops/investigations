---
title: FCR source comparison deep dive
sidebar_position: 1
description: Follow-up to the FCR implementation divergence investigation. Compares block-included against gossip-pool attestation sources and traces the residual gap to late subnet arrivals past the aggregation deadline.
date: 2026-05-14T01:00:00Z
author: samcm
tags:
  - consensus
  - fast-confirmation
  - fork-choice
  - attestations
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    const jaccardBuckets = [
        { bucket: '< 0.980', count: 1 },
        { bucket: '0.980 to 0.990', count: 2 },
        { bucket: '0.990 to 0.995', count: 8 },
        { bucket: '0.995 to 0.998', count: 23 },
        { bucket: '0.998 to 0.999', count: 28 },
        { bucket: '0.999 to 0.9999', count: 141 },
        { bucket: '0.9999 to 1.0', count: 260 },
        { bucket: '1.000 (exact)', count: 337 }
    ];

    $: jaccardHistConfig = {
        title: { text: 'Per-slot Jaccard of canonical-head voter sets, 800 sampled slots', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (params) => `<b>${params[0].name}</b><br/>${params[0].value.toLocaleString()} slots (${(100*params[0].value/800).toFixed(1)}%)` },
        grid: { left: 130, right: 80, top: 60, bottom: 60 },
        xAxis: { type: 'value', name: 'slots', nameLocation: 'center', nameGap: 30 },
        yAxis: { type: 'category', data: jaccardBuckets.map(d => d.bucket), name: 'Jaccard bucket', nameLocation: 'center', nameGap: 110, nameRotate: 90 },
        series: [{
            type: 'bar',
            data: jaccardBuckets.map(d => ({ value: d.count, itemStyle: { color: '#2563eb' } })),
            label: { show: true, position: 'right', formatter: (p) => `${Number(p.value).toLocaleString()} (${(100*p.value/800).toFixed(1)}%)` }
        }]
    };

    const sentryGroups = [
        { label: 'utility-001 alone', mean: 30186.8 },
        { label: 'utility-003 alone', mean: 30186.8 },
        { label: 'utility-001 + 003 (2)', mean: 30186.8 },
        { label: 'subnet-attached (3)', mean: 9774.1 },
        { label: 'all 5 sentries', mean: 30186.8 }
    ];
    const blockMean = 30196.5;

    $: sentryCumulativeConfig = {
        title: { text: 'Mean canonical-head voter union across 800 slots, by sentry subset', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (params) => {
            let html = `<b>${params[0].axisValue}</b><br/>`;
            params.forEach(p => { html += `${p.marker} ${p.seriesName}: ${Number(p.value).toLocaleString()}<br/>`; });
            return html;
        }},
        grid: { left: 200, right: 120, top: 60, bottom: 50 },
        xAxis: { type: 'value', name: 'mean validators in union', nameLocation: 'center', nameGap: 30, min: 0, max: 32000 },
        yAxis: { type: 'category', data: sentryGroups.map(d => d.label) },
        series: [
            {
                name: 'gossip-pool union',
                type: 'bar',
                data: sentryGroups.map(d => d.mean),
                itemStyle: { color: '#2563eb' },
                label: { show: true, position: 'right', formatter: (p) => Number(p.value).toLocaleString() },
                markLine: {
                    silent: true,
                    symbol: 'none',
                    label: { formatter: 'block-included mean: 30,196.5', position: 'insideEndTop', fontSize: 11, color: '#16a34a' },
                    lineStyle: { color: '#16a34a', type: 'dashed' },
                    data: [{ xAxis: blockMean }]
                }
            }
        ]
    };

    const slicesData = [
        { metric: 'mean count delta',  disagreement: 10.1, agreement: 9.3 },
        { metric: 'mean weight delta (ETH)', disagreement: 412.7, agreement: 362.0 },
        { metric: 'p75 count delta', disagreement: 4, agreement: 3 },
        { metric: 'p90 count delta', disagreement: 15, agreement: 11 },
        { metric: 'mean Jaccard',    disagreement: 0.99966, agreement: 0.99970 }
    ];

    // Subnet first-seen timing distribution: agg-hits vs agg-misses
    // 1,995 sample slots, 60,991,928 hit voter-events, 16,049 miss voter-events
    const timingBuckets = [
        { bucket: '0-1s',     hit: 41801,    miss: 0 },
        { bucket: '1-2s',     hit: 2156981,  miss: 0 },
        { bucket: '2-3s',     hit: 11475059, miss: 0 },
        { bucket: '3-4s',     hit: 11221834, miss: 0 },
        { bucket: '4-5s',     hit: 21472462, miss: 107 },
        { bucket: '5-6s',     hit: 11956328, miss: 235 },
        { bucket: '6-7s',     hit: 2412874,  miss: 501 },
        { bucket: '7-8s',     hit: 222017,   miss: 176 },
        { bucket: '8-10s',    hit: 20363,    miss: 11871 },
        { bucket: '10-12s',   hit: 578,      miss: 1735 },
        { bucket: '12-16s',   hit: 3913,     miss: 807 },
        { bucket: '16-24s',   hit: 1270,     miss: 406 },
        { bucket: '24s+',     hit: 6448,     miss: 211 }
    ];
    const hitTotal = timingBuckets.reduce((s,d) => s + d.hit, 0);
    const missTotal = timingBuckets.reduce((s,d) => s + d.miss, 0);

    $: timingHistConfig = {
        title: { text: 'Subnet first-seen propagation_slot_start_diff: agg-hits vs agg-misses', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' },
            formatter: (params) => {
                let html = `<b>${params[0].axisValue}</b><br/>`;
                params.forEach(p => {
                    const total = p.seriesName.includes('hits') ? hitTotal : missTotal;
                    html += `${p.marker} ${p.seriesName}: ${Number(p.value).toLocaleString()} (${(100*p.value/total).toFixed(2)}%)<br/>`;
                });
                return html;
            }
        },
        legend: { top: 28 },
        grid: { left: 80, right: 80, top: 70, bottom: 60 },
        xAxis: { type: 'category', data: timingBuckets.map(d => d.bucket), name: 'subnet first-seen bucket', nameLocation: 'center', nameGap: 30 },
        yAxis: [
            { type: 'value', name: '% of agg-hits', nameLocation: 'center', nameGap: 50, position: 'left', max: 40 },
            { type: 'value', name: '% of agg-misses', nameLocation: 'center', nameGap: 50, position: 'right', max: 80 }
        ],
        series: [
            {
                name: 'agg-hits (n=61.0M)',
                type: 'bar',
                yAxisIndex: 0,
                data: timingBuckets.map(d => +(100*d.hit/hitTotal).toFixed(3)),
                itemStyle: { color: '#16a34a' }
            },
            {
                name: 'agg-misses (n=16,049)',
                type: 'bar',
                yAxisIndex: 1,
                data: timingBuckets.map(d => +(100*d.miss/missTotal).toFixed(3)),
                itemStyle: { color: '#dc2626' },
                markLine: {
                    silent: true,
                    symbol: 'none',
                    label: { formatter: '8s deadline', position: 'insideEndTop', fontSize: 11, color: '#374151' },
                    lineStyle: { color: '#374151', type: 'dashed' },
                    data: [{ xAxis: '8-10s' }]
                }
            }
        ]
    };

    // MEV-built vs locally-built agg-miss timing.
    // Built from cross-join: canonical_beacon_block.execution_payload_block_hash matched against mev_relay_proposer_payload_delivered.block_hash.
    // 1,824 MEV slots (13,991 agg-miss validators with timing), 167 local slots (1,126 agg-miss validators with timing).
    // 2 slots in the original 1,995-slot sample had no canonical_beacon_block row (proposer missed the slot) and are excluded.
    const mevSplitBuckets = [
        { bucket: '0-1s',   mev: 0,     local: 0 },
        { bucket: '1-2s',   mev: 0,     local: 0 },
        { bucket: '2-3s',   mev: 0,     local: 0 },
        { bucket: '3-4s',   mev: 0,     local: 0 },
        { bucket: '4-5s',   mev: 0,     local: 0 },
        { bucket: '5-6s',   mev: 4,     local: 0 },
        { bucket: '6-7s',   mev: 0,     local: 0 },
        { bucket: '7-8s',   mev: 91,    local: 0 },
        { bucket: '8-10s',  mev: 10863, local: 1008 },
        { bucket: '10-12s', mev: 1673,  local: 54 },
        { bucket: '12-16s', mev: 782,   local: 25 },
        { bucket: '16-24s', mev: 378,   local: 28 },
        { bucket: '24s+',   mev: 200,   local: 11 }
    ];
    const mevTotal = mevSplitBuckets.reduce((s,d) => s + d.mev, 0);
    const localTotal = mevSplitBuckets.reduce((s,d) => s + d.local, 0);

    $: mevSplitHistConfig = {
        title: { text: 'Agg-miss subnet first-seen: MEV-built (n=13,991) vs locally-built (n=1,126)', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' },
            formatter: (params) => {
                let html = `<b>${params[0].axisValue}</b><br/>`;
                params.forEach(p => {
                    const total = p.seriesName.startsWith('MEV') ? mevTotal : localTotal;
                    html += `${p.marker} ${p.seriesName}: ${Number(p.value).toLocaleString()}% (${Math.round(p.value*total/100).toLocaleString()} validators)<br/>`;
                });
                return html;
            }
        },
        legend: { top: 28 },
        grid: { left: 80, right: 80, top: 70, bottom: 60 },
        xAxis: { type: 'category', data: mevSplitBuckets.map(d => d.bucket), name: 'subnet first-seen bucket', nameLocation: 'center', nameGap: 30 },
        yAxis: { type: 'value', name: '% of agg-misses (group)', nameLocation: 'center', nameGap: 50, max: 100 },
        series: [
            {
                name: 'MEV-built (n=1,824 slots)',
                type: 'bar',
                data: mevSplitBuckets.map(d => +(100*d.mev/mevTotal).toFixed(2)),
                itemStyle: { color: '#7c3aed' }
            },
            {
                name: 'Locally-built (n=167 slots)',
                type: 'bar',
                data: mevSplitBuckets.map(d => +(100*d.local/localTotal).toFixed(2)),
                itemStyle: { color: '#f59e0b' },
                markLine: {
                    silent: true,
                    symbol: 'none',
                    label: { formatter: '8s deadline', position: 'insideEndTop', fontSize: 11, color: '#374151' },
                    lineStyle: { color: '#374151', type: 'dashed' },
                    data: [{ xAxis: '8-10s' }]
                }
            }
        ]
    };
</script>

<PageMeta
    date="2026-05-14T01:00:00Z"
    author="samcm"
    tags={["consensus", "fast-confirmation", "fork-choice", "attestations"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-06T00:00:00Z"
    endTime="2026-01-02T23:59:59Z"
/>

<Section type="question">

## Question

The [previous investigation](../fcr-implementation-divergence/) sampled 299 slots and put the gap between the two FCR attestation sources at about 0.25% of committee. That was a single per-slot count, which is coarse. Does the conclusion hold at a finer grain — how do the two sets overlap, what changes when you weight by effective balance, and how much of the gossip view depends on having all 5 sentries up?

</Section>

<Section type="background">

## Background

The previous investigation traced a 1.15 pp Fast Confirmation Rule disagreement between Lighthouse and the Teku branch to a non-spec `support_discount` term. As a side check, it counted distinct canonical-head voters per source across 299 slots.

The two sources:

- **Block-included**: aggregates from canonical block bodies (`canonical_beacon_elaborated_attestation`), capped at `MAX_ATTESTATIONS_ELECTRA = 8` per block. Used by the Lighthouse FCR simulator.
- **Gossip-pool (5 sentries)**: aggregate-and-proof messages from 5 sentry clients (`libp2p_gossipsub_aggregate_and_proof`), with `aggregation_bits` decoded against `canonical_beacon_committee`. Used by the Teku branch.

This page resamples 800 slots (400 disagreement, 400 random) for the main comparison, then scales to 1,995 slots for the timing analysis.

</Section>

<Section type="investigation">

## Investigation

### When measuring per-slot overlap

<ECharts config={jaccardHistConfig} height="380px" />

| Bucket | Slots | Share |
|---|---:|---:|
| 1.000 (exact) | 337 | 42.1% |
| 0.9999 to 1.0 | 260 | 32.5% |
| 0.999 to 0.9999 | 141 | 17.6% |
| 0.998 to 0.999 | 28 | 3.5% |
| 0.995 to 0.998 | 23 | 2.9% |
| 0.990 to 0.995 | 8 | 1.0% |
| 0.980 to 0.990 | 2 | 0.3% |
| `< 0.980` | 1 | 0.1% |

Mean Jaccard 0.99968, median 0.99997, p10 still 0.9996.

| Metric | Mean | Median | p75 | p90 | Max |
|---|---:|---:|---:|---:|---:|
| block voters | 30,196 | 30,615 | 30,881 | 30,936 | 31,026 |
| gossip voters (5-sentry union) | 30,187 | 30,604 | 30,873 | 30,931 | 31,024 |
| `block_only` | 9.7 | 1 | 3 | 12 | 642 |
| `gossip_only` | 0 | 0 | 0 | 0 | **0** |

`gossip_only` is zero on every one of the 800 slots — gossip is a strict subset of block-included. The 0.25% gap is "block has a few extra voters the sentries missed," not "the two sides see different populations."

### When weighting by effective balance

Electra effective balances range 32 to 2048 ETH (EIP-7251). 4,560 of the ~964k active validators are compounded (0.47%), so a single missed compounded validator can move weight far more than count.

| Metric | Mean | Median | p75 | p90 | Max |
|---|---:|---:|---:|---:|---:|
| block weight (ETH) | 1,074,645 | 1,083,883 | 1,098,978 | 1,109,046 | 1,140,343 |
| gossip weight (ETH) | 1,074,257 | 1,083,750 | 1,098,815 | 1,108,562 | 1,136,311 |
| `block_only` weight (ETH) | 387 | 32 | 96 | 480 | 22,229 |

Median block-only weight 32 ETH matches median count 1 — a plain validator. Compounded share of block-only events is 0.86% vs 0.47% baseline (1.8× enrichment, still under 1%). Weight tracks count.

### When dropping sentries

The 5 sentries don't contribute equally. Two utility sentries (`utility-mainnet-lighthouse-geth-001` / `-003`) were up for all 800 slots and saw every committee. The other 3 (`xatu-sentry-sfo3-mainnet-lighthouse-nethermind-1d`, `xatu-tysm-ams3-mainnet-003-subnets-0-1`, `xatu-tysm-ams3-mainnet-005-subnets-0-1`) only emitted rows for 255/800 slots, and their voter sets were always a subset.

<ECharts config={sentryCumulativeConfig} height="280px" />

| Sentry subset | Mean voters in union | Mean Jaccard vs block | Mean `block_only` |
|---|---:|---:|---:|
| utility-001 alone | 30,186.8 | 0.99968 | 9.7 |
| utility-003 alone | 30,186.8 | 0.99968 | 9.7 |
| utility-001 + 003 (2) | 30,186.8 | 0.99968 | 9.7 |
| subnet-attached only (3) | 9,774.1 | 0.32238 | 20,422 |
| all 5 sentries | 30,186.8 | 0.99968 | 9.7 |

The "5-sentry pipeline" is operationally a 1-sentry pipeline as long as either utility is up.

### When splitting disagreement vs agreement slots

| Metric | Disagreement slots (n=400) | Agreement slots (n=400) |
|---|---:|---:|
| mean count delta (block − gossip) | 10.1 | 9.3 |
| mean weight delta (ETH) | 413 | 362 |
| p75 count delta | 4 | 3 |
| p90 count delta | 15 | 11 |
| mean Jaccard | 0.99966 | 0.99970 |

The 0.8-voter and 50-ETH gaps sit inside per-slot noise. The source delta didn't carve the disagreement set; `support_discount` did.

### When asking why gossip falls short

A utility sentry sees every committee and still misses ~10 voters per slot. Two gossipsub topics carry attestation data: `beacon_aggregate_and_proof` (aggregators broadcast one aggregate per committee) and `beacon_attestation_<subnet>` (every validator broadcasts on their subnet). The Teku replay uses only the first; block proposers pull from both via the peer mempool.

Re-running on 1,995 slots with both topics decoded:

| Source | Mean | Median | p90 | p99 | Mean gap vs block |
|---|---:|---:|---:|---:|---:|
| Block-included | 30,640 | 30,796 | 30,951 | 31,005 | (baseline) |
| Subnet single-attestation | 30,580 | 30,766 | 30,948 | 31,004 | 59.2 |
| Aggregate-and-proof | 30,632 | 30,790 | 30,949 | 30,999 | 8.1 |

The 59.2 block-minus-subnet mean is dragged up by 165 outage slots; on the remaining 1,830 clean slots it drops to 3.1 vs block-minus-agg 8.4. The subnet topic closes most of the gap.

So why does the agg topic miss ~8 per slot? Of the 16,049 agg-miss validators the subnet *did* observe, per-validator min `propagation_slot_start_diff` lines up like this:

<ECharts config={timingHistConfig} height="400px" />

| Percentile | agg-hits (n=61.0M) | agg-misses (n=16,049) |
|---|---:|---:|
| p25 | 3,113 ms | 8,270 ms |
| p50 | 4,313 ms | 8,732 ms |
| p75 | 4,971 ms | 9,507 ms |
| p90 | 5,513 ms | 11,755 ms |
| p95 | 5,923 ms | 14,756 ms |
| p99 | 6,683 ms | 28,911 ms |
| mean | 4,113 ms | 10,072 ms |

| Threshold | % of agg-hits past | % of agg-misses past |
|---|---:|---:|
| > 4,000 ms | 59.17% | 100.00% |
| > 6,000 ms | 4.37% | 97.87% |
| > 8,000 ms | 0.05% | **93.63%** |
| > 12,000 ms | 0.02% | 8.87% |
| > 16,000 ms | 0.01% | 3.83% |

93.6% of agg-misses arrived on the subnet after the 8-second aggregation deadline. Only 1,022 (6.4%) were on time but still missed; another 189 never appeared on any subnet sentry yet landed in a canonical block. Block proposers scoop late attesters up because their inclusion window extends into the next slot; an agg-and-proof subscriber can't.

### When splitting by MEV builder

MEV-relay builders subscribe to every subnet and have an incentive to capture every attestation. Joining canonical `execution_payload_block_hash` to `mev_relay_proposer_payload_delivered.block_hash` classifies 1,824 slots as MEV-built across 8 relays, 167 locally-built, 4 unclassifiable.

| Metric | MEV-built (n=1,824) | Locally-built (n=167) |
|---|---:|---:|
| mean block_minus_agg | 7.77 | 6.84 |
| median block_minus_agg | 1 | 0 |
| agg-miss validators with timing | 13,991 | 1,126 |
| agg-misses > 8s | 99.30% | 100.00% |
| agg-misses > 12s | 9.72% | 5.68% |
| agg-miss p90 first-seen | 11,873 ms | 10,179 ms |
| agg-miss p99 first-seen | 29,882 ms | 23,979 ms |

<ECharts config={mevSplitHistConfig} height="380px" />

Post-8s share is ~100% in both groups; late arrival is structural, not a builder choice. MEV-built blocks do pull more in the upper tail (p90 11.9s vs 10.2s, p99 29.9s vs 24.0s), but the 0.93 voters/slot mean difference sits inside per-slot noise of ~±10. With only 167 local slots, the upper-tail divergence is the only signal.

</Section>

<Section type="takeaways">

## Takeaways

- The ~10-voters-per-slot block-included surplus over aggregate-and-proof gossip is dominated by **late subnet arrivals**. 93.6% of agg-misses with timing data landed on the subnet after the 8-second aggregation deadline; on cleanly classifiable slots it's ~100%.
- The single-attestation topic closes most of the gap (block-minus-subnet 3.1 vs block-minus-agg 8.4 on clean slots). Agg-and-proof is a structurally on-time view; block-included and single-attestation aren't.
- The 5-sentry pipeline is operationally a 1-sentry pipeline. Either utility sentry alone gives mean Jaccard 0.99968; the other 4 add nothing. Weight tracks count (median delta 32 ETH = 1 plain validator).
- The source delta does not track the FCR disagreement. The 1.15 pp gap is still `support_discount`, not the data source.

</Section>
