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

The [previous investigation](../fcr-implementation-divergence/) traced a 1.15 pp Fast Confirmation Rule disagreement between two offline FCR simulators to a non-spec `support_discount` term. The two simulators also read different inputs: one uses attestations from canonical block bodies, the other uses sentry gossip. Could the input difference itself be moving the FCR verdict, or is `support_discount` doing all the work?

</Section>

<Section type="background">

## Background

Two offline FCR simulators replay mainnet slot-by-slot and decide whether the Fast Confirmation Rule would have fired:

- **Lighthouse-style**: reads attestations from canonical block bodies (`canonical_beacon_elaborated_attestation`), capped at `MAX_ATTESTATIONS_ELECTRA = 8` per block.
- **Teku-style**: reads `beacon_aggregate_and_proof` gossip from 5 Xatu sentries (`libp2p_gossipsub_aggregate_and_proof`), decoding `aggregation_bits` against `canonical_beacon_committee`.

They disagree on 1.15% of slots. The previous investigation isolated the cause to `support_discount`. This page tests whether the input source is *also* implicated, by comparing the actual voter sets the two simulators see slot-by-slot.

800 slots (400 disagreement, 400 random) for the per-slot overlap; 1,995 slots for the timing analysis.

</Section>

<Section type="investigation">

## Investigation

### When comparing the two voter sets per slot

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

`gossip_only` is zero on every one of the 800 slots; gossip is a strict subset of block-included. Block has ~10 extra voters per slot (0.03% of committee). The two inputs see effectively the same population, with a small structural surplus on the block side.

That ~10 already rules out the input source as a 1.15pp driver. Even if every missed voter happened to flip the FCR verdict (they don't), the input could account for at most ~0.03pp.

### When explaining where those ~10 come from

The Teku-style simulator only subscribes to the `beacon_aggregate_and_proof` topic. Two protocol facts push voters into the block but not into that topic:

1. **Aggregators select at t=8s.** Every aggregator picks its aggregate at t=8s into the slot and broadcasts it on `beacon_aggregate_and_proof`. Nothing structurally aggregates after that, so any single attestation that arrives later has no path into the agg-and-proof topic.
2. **Block proposers see late attestations anyway.** The proposer for slot N+1 finalizes block contents around the start of N+1 (~t=12s of slot N), giving them ~4s past the aggregator cutoff. They also pull from both gossip topics (aggregates AND `beacon_attestation_<subnet>`) plus their peer attestation mempool. Late single-attestations make it in.

Adding the single-attestation topic to the simulator's input proves the mechanism. Re-running on 1,995 slots:

| Source | Mean | Median | p90 | p99 | Mean gap vs block |
|---|---:|---:|---:|---:|---:|
| Block-included | 30,640 | 30,796 | 30,951 | 31,005 | (baseline) |
| Subnet single-attestation | 30,580 | 30,766 | 30,948 | 31,004 | 59.2 |
| Aggregate-and-proof | 30,632 | 30,790 | 30,949 | 30,999 | 8.1 |

Block-minus-agg drops from 8.1 to 3.1 voters/slot once the subnet topic is included (the raw 59.2 block-minus-subnet number is dragged up by 165 outage slots; on the 1,830 clean slots it's 3.1).

A vanilla beacon node only listens to 2 of 64 single-attestation subnets, so no single sentry can decode the full subnet topic on its own. The 5-sentry pool collectively covers more, which is why this analysis can read the subnet topic at all.

To confirm the timing story: of the 16,049 agg-miss validators that the subnet *did* observe, per-validator min `propagation_slot_start_diff` lines up like this:

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

93.6% of agg-misses arrived on a subnet after the 8s aggregator cutoff. Only 1,022 (6.4%) were on time but still missed; another 189 never appeared on any subnet sentry yet landed in a canonical block (almost certainly via someone's peer mempool).

### When splitting by MEV builder

MEV-relay builders subscribe to all 64 subnets to maximize attestation inclusion, vs vanilla builders on 2. Does that change the late-arrival pattern? Joining canonical `execution_payload_block_hash` to `mev_relay_proposer_payload_delivered.block_hash` classifies 1,824 slots as MEV-built across 8 relays, 167 locally-built, 4 unclassifiable.

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

Post-8s share is ~100% in both groups; late arrival is structural, not a builder choice. MEV-built blocks do pull more in the upper tail (p90 11.9s vs 10.2s, p99 29.9s vs 24.0s), consistent with wider subnet coverage and bigger peer mempools, but the 0.93 voters/slot mean difference sits inside per-slot noise of ~±10. The 167 local slots are too few to make the upper-tail divergence load-bearing.

</Section>

<Section type="takeaways">

## Takeaways

- **The input source is not the FCR culprit.** The two voter sets agree 99.97% per-slot; the ~10-voter block surplus could move FCR by at most ~0.03pp. The 1.15pp simulator disagreement is `support_discount`, not the data source. Switching the Teku-style simulator to read block-included would not close it.
- **The ~10/slot block surplus is structural to reading only `aggregate_and_proof`.** That topic has an effective 8s aggregator cutoff; 93.6% of missed voters arrived on the single-attestation subnet topic after 8s. Block proposers grab them via both topics + peer mempool + the ~4s before the next block is built.
- **Adding the single-attestation subnet topic closes most of the gap** (3.1 vs 8.4 voters/slot on clean slots), at the cost of much higher gossip volume. Worth it if you want a gossip-only view that tracks block-inclusion closely.

</Section>
