---
title: FCR source comparison deep dive
sidebar_position: 1
description: Follow-up to the FCR implementation divergence investigation. Compares the block-included and gossip-pool attestation sources on 800 sampled slots from the same window, with per-slot Jaccard, effective-balance weight, per-sentry contribution, and disagreement-vs-agreement deltas. Adds a 1,995-slot timing analysis showing the aggregate-and-proof shortfall is dominated by validators whose subnet attestations arrived after the 8-second aggregation deadline.
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

The [previous investigation](../fcr-implementation-divergence/) sampled 299 slots and reported the gap between the two FCR attestation data sources at about 0.25% of committee. That was a single per-slot distinct-validator count, which is coarse. Does the conclusion hold at a finer grain? How do the two sets actually overlap, what does it look like once you weight by effective balance, and how much of the gossip view depends on having all 5 sentries up?

</Section>

<Section type="background">

## Background

The previous investigation traced a 1.15 pp Fast Confirmation Rule disagreement between Lighthouse and the Teku branch to a non-spec `support_discount` term. As a side check, it sampled 299 slots and counted distinct validators voting for the canonical head from each source.

The two sources are:

- **Block-included**: aggregates extracted from canonical block bodies, capped per Electra at `MAX_ATTESTATIONS_ELECTRA = 8` aggregates per block. Stored in xatu's `canonical_beacon_elaborated_attestation` with a pre-decoded `validators` array. The Lighthouse FCR simulator uses this.
- **Gossip-pool (5 sentries)**: aggregate-and-proof messages observed by 5 specific sentry clients. Stored in `libp2p_gossipsub_aggregate_and_proof` with raw `aggregation_bits`. The Teku branch uses this.

The 299-slot check found block-side averaged 76 more distinct voters than gossip per slot (~0.25% of committee) and concluded the gap was inside the noise floor. This page resamples 800 slots from the same window (400 from the 2,388 Teku-yes / Lighthouse-no disagreement set, plus 400 random from the rest), pulls per-slot block-included voters via SQL, decodes the gossip side bit-by-bit against historical committees from `canonical_beacon_committee`, and runs the comparison.

</Section>

<Section type="investigation">

## Investigation

### When sampling 800 slots and decoding both sides

For each of the 800 sample slots S, we get:

- The canonical block at slot S from `canonical_beacon_block` (the `block_root` for the head vote).
- All distinct validators with `(slot=S, beacon_block_root=root(S))` from `canonical_beacon_elaborated_attestation`, flattened from the `validators` array.
- For each of the 5 sentries, per-(slot, committee_index): the union of `aggregation_bits` over all observed aggregate-and-proof messages with `(slot=S, beacon_block_root=root(S))`. Bit positions are decoded against `canonical_beacon_committee.validators` to recover validator indices.

The block-included query benefits from a `(slot, beacon_block_root)` tuple IN clause:

```bash
panda clickhouse query xatu "
SELECT slot, arraySort(groupUniqArray(v)) AS voters
FROM (
  SELECT slot, beacon_block_root, arrayJoin(validators) AS v
  FROM canonical_beacon_elaborated_attestation
  WHERE meta_network_name = 'mainnet'
    AND slot_start_date_time BETWEEN toDateTime('2025-12-06 14:48:23')
                                 AND toDateTime('2026-01-02 21:25:11')
    AND slot BETWEEN 13184040 AND 13380419
    AND (slot, beacon_block_root) IN (
      (13184040, '0x7720de73...'), (13184113, '0x60400bf6...'), ...
    )
)
GROUP BY slot
FORMAT JSONEachRow
"
```

After the merge each slot has a `block_voters` set and, separately, a `gossip_voters` set per sentry plus a 5-sentry union. The rest of the investigation works off those sets.

### When measuring per-slot overlap

Per-slot Jaccard is close to 1 almost everywhere.

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

Mean Jaccard 0.99968. Median 0.99997. p10 (worst 10%) is still 0.9996.

What makes up the gap matters more than the Jaccard number itself. Across the 800 slots:

| Metric | Mean | Median | p75 | p90 | Max |
|---|---:|---:|---:|---:|---:|
| block voters | 30,196 | 30,615 | 30,881 | 30,936 | 31,026 |
| gossip voters (5-sentry union) | 30,187 | 30,604 | 30,873 | 30,931 | 31,024 |
| `block_only` | 9.7 | 1 | 3 | 12 | 642 |
| `gossip_only` | 0 | 0 | 0 | 0 | **0** |

`gossip_only` is zero for every single one of the 800 slots. The gossip-pool view is a strict subset of the block-included view in this sample. Block-side has 7,140 distinct validators that the gossip side never saw for the canonical head; the gossip side has zero unique validators. The 0.25% gap from the previous investigation is "block has a few extra voters the sentries missed", not "the two sides see different populations". A balanced symmetric difference would point at each side having its own blind spots; this one is fully one-sided.

### When weighting by effective balance

Electra effective balance ranges 32 to 2048 ETH (EIP-7251 compounded validators). 4,560 of the ~964k active validators in the window were compounded (0.47%), heaviest at 2048 ETH. So a single missed compounded validator can move the weight delta much more than it moves the count delta.

Per-slot delta in ETH:

| Metric | Mean | Median | p75 | p90 | Max |
|---|---:|---:|---:|---:|---:|
| block weight (ETH) | 1,074,645 | 1,083,883 | 1,098,978 | 1,109,046 | 1,140,343 |
| gossip weight (ETH) | 1,074,257 | 1,083,750 | 1,098,815 | 1,108,562 | 1,136,311 |
| `block_only` weight (ETH) | 387 | 32 | 96 | 480 | 22,229 |

Median block-only weight delta is 32 ETH, matching the median count delta of 1 voter: a plain 32-ETH validator. The p90 weight delta is 480 ETH against a p90 count of 12; 12 plain voters would be 384 ETH. The 25% surplus says the typical block-only voter is a bit heavier than vanilla. Of the 7,751 block-only voter-events, 67 (0.86%) are compounded validators, against an active-validator baseline of 0.47%. Mild enrichment, factor 1.8, absolute share still under 1%. The largest single-slot weight delta is 22,229 ETH on slot 13,285,305 (642 block-only voters, also the worst-Jaccard slot).

Weight tracks count closely. The count picture holds.

### When dropping sentries

The 5 sentries do not contribute equally. The two utility sentries (`utility-mainnet-lighthouse-geth-001` and `-003`) were up for all 800 slots and observed at least one aggregate from every one of the 64 committees in every slot. Each one alone captures about 99.97% of the canonical-head voters, with a mean shortfall of ~9.7 voters per slot. The other 3 sentries (`xatu-sentry-sfo3-mainnet-lighthouse-nethermind-1d`, `xatu-tysm-ams3-mainnet-003-subnets-0-1`, `xatu-tysm-ams3-mainnet-005-subnets-0-1`) only emitted aggregate-and-proof rows for 255 of 800 slots (32%); when up, their voter sets were a strict subset of the utility sentries'.

<ECharts config={sentryCumulativeConfig} height="280px" />

| Sentry subset | Mean voters in union | Mean Jaccard vs block | Mean `block_only` |
|---|---:|---:|---:|
| utility-001 alone | 30,186.8 | 0.99968 | 9.7 |
| utility-003 alone | 30,186.8 | 0.99968 | 9.7 |
| utility-001 + 003 (2) | 30,186.8 | 0.99968 | 9.7 |
| subnet-attached only (3) | 9,774.1 | 0.32238 | 20,422 |
| all 5 sentries | 30,186.8 | 0.99968 | 9.7 |

A single utility sentry delivers the same view as all 5 combined. The second utility adds nothing (identical voter sets when both are up). The 3 subnet-attached sentries add nothing on top. The "5-sentry pipeline" is operationally a 1-sentry pipeline as long as either utility is up; if the utilities had been down together, the gossip side would have been silent for hundreds of slots in this window. The 1-utility view still falls short of block-included by ~9.7 voters per slot, so being inside one utility's set is not the same as being inside the canonical chain.

### When splitting disagreement vs agreement slots

The previous investigation pinned the implementation gap to logic, not data, so we shouldn't expect the source delta to track the FCR disagreement. Confirming check:

| Metric | Disagreement slots (n=400) | Agreement slots (n=400) |
|---|---:|---:|
| mean count delta (block − gossip) | 10.1 | 9.3 |
| mean weight delta (ETH) | 413 | 362 |
| p75 count delta | 4 | 3 |
| p90 count delta | 15 | 11 |
| mean Jaccard | 0.99966 | 0.99970 |

Disagreement slots have a marginally larger source delta (0.8 more block-only voters, 50 ETH of weight). Both distributions are skewed with a thin tail and the means sit within noise. The source delta didn't carve the 2,388-slot disagreement; the `support_discount` term from the previous investigation did.

### When asking why gossip falls short

If a single utility sentry sees every committee yet still misses ~10 voters per slot, what does it miss? Two gossipsub topics carry attestation data on mainnet:

- `beacon_aggregate_and_proof`: designated aggregators broadcast a single aggregate per committee
- `beacon_attestation_<subnet>`: every validator broadcasts their individual attestation on their committee's subnet

The Teku replay uses only the aggregate-and-proof topic. A subscriber sees a validator's vote only if (a) an aggregator was selected that included it and (b) that aggregate-and-proof message reached the sentry. Block proposers subscribe to both topics and pull from their full peer mempool, so they catch every validator.

To test the topic-choice claim at scale, we re-ran the comparison on 1,995 sampled slots (every ~98th slot from December 6 2025 to January 2 2026), pulled per-validator first-seen times from the subnet topic, decoded `aggregation_bits` from `libp2p_gossipsub_aggregate_and_proof` against `canonical_beacon_committee`, and lined the three sets up per slot.

Per slot, mean validators voting canonical head:

| Source | Mean | Median | p90 | p99 | Per-slot gap vs block (mean) |
|---|---:|---:|---:|---:|---:|
| Block-included | 30,640 | 30,796 | 30,951 | 31,005 | (baseline) |
| Subnet single-attestation (5 sentries) | 30,580 | 30,766 | 30,948 | 31,004 | 59.2 |
| Aggregate-and-proof (5 sentries) | 30,632 | 30,790 | 30,949 | 30,999 | 8.1 |

Aggregate-and-proof on the larger sample still trails block-included by 8.1 voters per slot (p90 = 8, p99 = 153). The 59.2 block-minus-subnet mean is dragged up by 165 slots where the subnet stream had a broad outage (max 30,611). On the remaining 1,830 clean slots, block-minus-subnet drops to 3.1 voters per slot vs block-minus-agg 8.4. In a typical slot the subnet topic closes most of the gap.

That leaves the mechanism. Of the ~8 agg-misses per slot, why didn't aggregate-and-proof gossip cover them? Three hypotheses:

1. **Late subnet arrival.** The validator's subnet attestation arrived after the 8-second aggregation deadline (4s for the attestation, 8s for the aggregator to publish). The aggregator on duty had nothing to include.
2. **Aggregator gossip never reached us.** The subnet attestation was on time, an aggregator covered it, but the aggregate-and-proof message never reached any of the 5 sentries.
3. **Aggregator didn't include them.** The validator was on time on the subnet, but the chosen aggregator built an aggregate that omitted them.

Across the 1,995 slots we found 16,049 agg-miss validators that the subnet topic *did* observe (so timing is available for each). For each, we take the per-validator min `propagation_slot_start_diff` across the 5 sentries.

<ECharts config={timingHistConfig} height="400px" />

| Percentile | agg-hits subnet first-seen (n=61.0M) | agg-misses subnet first-seen (n=16,049) |
|---|---:|---:|
| p25 | 3,113 ms | 8,270 ms |
| p50 (median) | 4,313 ms | 8,732 ms |
| p75 | 4,971 ms | 9,507 ms |
| p90 | 5,513 ms | 11,755 ms |
| p95 | 5,923 ms | 14,756 ms |
| p99 | 6,683 ms | 28,911 ms |
| mean | 4,113 ms | 10,072 ms |

The two distributions barely overlap. Hits cluster in the 3-6 second window where validators are *supposed* to attest. Misses cluster after the 8-second aggregation deadline.

| Threshold | % of agg-hits past | % of agg-misses past |
|---|---:|---:|
| > 4,000 ms | 59.17% | 100.00% |
| > 6,000 ms | 4.37% | 97.87% |
| > 8,000 ms | 0.05% | **93.63%** |
| > 12,000 ms | 0.02% | 8.87% |
| > 16,000 ms | 0.01% | 3.83% |

93.6% of agg-misses with timing data arrived on the subnet *after* the 8-second deadline. Only 6.4% (1,022 of 16,049) arrived in time and still failed to make any observed aggregate. A further 189 agg-misses (0.1 per slot) never appeared on the subnet at any sentry yet still landed in the canonical block: the only fragment that could be hypothesis 2 or 3.

Hypothesis 1 wins by an order of magnitude. The validators that block-included captures but aggregate-and-proof gossip misses are mostly ones whose own subnet attestation arrived too late for any aggregator to include. Block proposers scoop them up because their inclusion window extends into the next slot; an aggregate-and-proof subscriber cannot. The single-attestation topic doesn't just see "more" voters, it sees the late attesters who show up between 8 and 12 seconds. For replaying live aggregator behavior, the agg topic is the right source; for matching what makes it into the canonical block, the subnet topic is.

### When splitting by MEV builder

MEV-relay builders run dedicated nodes subscribed to every attestation subnet and have a financial incentive to capture every last attestation. Locally-built blocks come from the proposer's own consensus client, which is typically subscribed to a small subset of subnets. If builders pull more aggressively, MEV-built blocks should show a larger block-minus-agg surplus and a heavier post-deadline tail.

Classification joins each sample slot's canonical `execution_payload_block_hash` from `canonical_beacon_block` to `mev_relay_proposer_payload_delivered.block_hash` across every tracked relay. 1,824 slots (91.4%) were MEV-built across 8 relays (Ultra Sound, BloXroute Max Profit, Titan, Aestus, BloXroute Regulated, Agnostic Gnosis, EthGas, Flashbots), 167 were locally-built, and 4 were unclassifiable.

| Metric | MEV-built (n=1,824) | Locally-built (n=167) |
|---|---:|---:|
| mean block_minus_agg | 7.77 | 6.84 |
| median block_minus_agg | 1 | 0 |
| agg-miss validators with timing | 13,991 | 1,126 |
| agg-misses with subnet first-seen > 8s | 99.30% | 100.00% |
| agg-misses with subnet first-seen > 12s | 9.72% | 5.68% |

Subnet first-seen percentiles for the agg-miss set:

| Percentile | MEV-built | Locally-built |
|---|---:|---:|
| p50 | 8,816 ms | 8,708 ms |
| p75 | 9,680 ms | 9,338 ms |
| p90 | 11,873 ms | 10,179 ms |
| p95 | 15,272 ms | 12,826 ms |
| p99 | 29,882 ms | 23,979 ms |

<ECharts config={mevSplitHistConfig} height="380px" />

The post-8s deadline share is essentially 100% in both groups: 99.3% MEV, 100.0% local. The earlier 93.6% figure becomes ~100% once we restrict to cleanly classifiable slots; the difference was 2 outlier slots where the canonical block was missing from xatu and contaminated the agg-miss set. Late arrival is structural, not a builder choice.

In the upper tail MEV-built blocks do pull more late voters: p90 of agg-miss first-seen 11.9s vs 10.2s, p99 29.9s vs 24.0s, 9.72% past 12s vs 5.68%, mean block-minus-agg 7.77 vs 6.84. The hypothesis holds in a soft form. Builders capture more late voters than local proposers, but the effect is modest and both groups overwhelmingly source their block-only voters from the post-deadline tail.

Caveat: 167 slots is small. The local p25-p75 percentiles match the MEV group closely; only the upper tail diverges. The 0.93 voters/slot mean difference sits inside per-slot noise of about ±10 voters.

</Section>

<Section type="takeaways">

## Takeaways

- The ~10-voters-per-slot block-included surplus over aggregate-and-proof gossip is dominated by **late subnet arrivals**, not sentry coverage or gossip-mesh failures. 93.6% of agg-misses with timing data arrived on the subnet after the 8-second aggregation deadline; the MEV/local split pushes that to ~100% on cleanly classifiable slots. Block proposers (MEV-built and local alike) scoop these up because their inclusion window extends into the next slot.
- Switching to the single-attestation gossip topic (`libp2p_gossipsub_beacon_attestation`) with the same 5 sentries closes most of the gap. On the 1,830 slots without broad subnet outages, block-minus-subnet is 3.1 voters/slot vs block-minus-agg 8.4. Aggregate-and-proof gossip is a structurally on-time view; block-included and single-attestation gossip are not.
- The 5-sentry gossip pipeline is operationally a 1-sentry pipeline. Either utility sentry alone gives mean Jaccard 0.99968 against block-included; the second utility and all 3 subnet-attached sentries add nothing on top. Weight-by-effective-balance tracks count closely (median delta 32 ETH = 1 plain validator).
- The source delta does not track the FCR disagreement. Disagreement and agreement slots show indistinguishable per-slot count/weight distributions. The 1.15 pp implementation gap is still the `support_discount` term from the previous investigation, not the choice of data source.

</Section>
