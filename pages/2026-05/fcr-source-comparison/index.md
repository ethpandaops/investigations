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

The [previous investigation](../fcr-implementation-divergence/) sampled 299 slots and said the gap between the two FCR attestation data sources was small (about 0.25% of committee). That figure came from a single per-slot distinct-validator count, which is coarse. Does the conclusion hold at a finer grain? How do the two sets actually overlap, what does the picture look like once you weight by effective balance, and how much of the gossip view depends on having all 5 sentries up?

</Section>

<Section type="background">

## Background

The previous investigation [../fcr-implementation-divergence](../fcr-implementation-divergence/) traced a 1.15 pp Fast Confirmation Rule disagreement between Lighthouse and a Teku branch to a non-spec `support_discount` term. As a side check, it sampled 299 slots and counted distinct validators voting for the canonical head from each source.

The two sources are:

- **Block-included**: aggregates extracted from canonical block bodies, capped per Electra at `MAX_ATTESTATIONS_ELECTRA = 8` aggregates per block. Stored in xatu's `canonical_beacon_elaborated_attestation` with a pre-decoded `validators` array. The Lighthouse FCR simulator uses this.
- **Gossip-pool (5 sentries)**: aggregate-and-proof messages observed by 5 specific sentry clients. Stored in `libp2p_gossipsub_aggregate_and_proof` with raw `aggregation_bits`. The Teku branch uses this.

The 299-slot check found block-side averaged 76 more distinct voters than gossip per slot (~0.25% of committee) and concluded the gap was inside the noise floor. That left several questions:

- Are the two sets the same 99.75% with a small extra block-side bias, or do both sides have unique populations?
- Does the picture change when you weight by effective balance? Post-Electra (EIP-7251) effective balances range 32 to 2048 ETH, so a single compounded validator on one side can shift the weight number a lot more than the count number.
- How much does the gossip view degrade if some of the 5 sentries are down?
- Is the source delta correlated with the slots where FCR itself disagreed?

This page samples 800 slots from the same window (400 from the 2,388 Teku-yes / Lighthouse-no disagreement set, plus 400 random from the rest), pulls per-slot block-included voters via SQL, decodes the gossip side bit-by-bit against historical committees from `canonical_beacon_committee`, and runs the comparison.

</Section>

<Section type="investigation">

## Investigation

### When sampling 800 slots and decoding both sides

For each of the 800 sample slots S, we get:

- The canonical block at slot S from `canonical_beacon_block` (gives the `block_root` for the head vote).
- All distinct validators with `(slot=S, beacon_block_root=root(S))` from `canonical_beacon_elaborated_attestation`, flattened from the `validators` array.
- For each of the 5 sentries: per-(slot, committee_index), the union of `aggregation_bits` over all observed aggregate-and-proof messages with `(slot=S, beacon_block_root=root(S))`. Bit positions are decoded against `canonical_beacon_committee.validators` to recover validator indices.

The block-included query for the full 800-slot sample is the kind of thing that benefits from a `(slot, beacon_block_root)` tuple IN clause:

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

The per-slot Jaccard is almost everywhere very close to 1.

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

The interesting thing is what makes up the gap. Across the 800 slots:

| Metric | Mean | Median | p75 | p90 | Max |
|---|---:|---:|---:|---:|---:|
| block voters | 30,196 | 30,615 | 30,881 | 30,936 | 31,026 |
| gossip voters (5-sentry union) | 30,187 | 30,604 | 30,873 | 30,931 | 31,024 |
| `block_only` | 9.7 | 1 | 3 | 12 | 642 |
| `gossip_only` | 0 | 0 | 0 | 0 | **0** |

`gossip_only` is zero for every single one of the 800 slots. The gossip-pool view is a strict subset of the block-included view in this sample. Block-side has 7,140 distinct validators that the gossip side never saw for the canonical head; the gossip side has zero unique validators. The 0.25% gap from the previous investigation, broken down, is "block has a few extra voters the sentries missed", not "the two sides see different populations".

This is more informative than the bare count delta. A Jaccard of 0.999 with a balanced symmetric difference would tell a very different story (each side having its own blind spots) from one where the symmetric difference is one-sided. Here it is fully one-sided.

### When weighting by effective balance

In Electra, effective balance ranges 32 to 2048 ETH (EIP-7251 compounded validators). 4,560 of the ~964k active validators in the window were compounded (0.47%), with the heaviest at 2048 ETH. So a single missed compounded validator could move the weight delta much more than it moves the count delta.

Per-slot delta in ETH:

| Metric | Mean | Median | p75 | p90 | Max |
|---|---:|---:|---:|---:|---:|
| block weight (ETH) | 1,074,645 | 1,083,883 | 1,098,978 | 1,109,046 | 1,140,343 |
| gossip weight (ETH) | 1,074,257 | 1,083,750 | 1,098,815 | 1,108,562 | 1,136,311 |
| `block_only` weight (ETH) | 387 | 32 | 96 | 480 | 22,229 |

The median block-only weight delta is exactly 32 ETH, which lines up with the median count delta of 1 voter: that one voter is a plain 32-ETH validator. The p90 weight delta of 480 ETH against a p90 count delta of 12 voters would be 12 x 32 = 384 ETH if every voter were plain. The actual 480 ETH is about 25% higher, so the typical block-only voter is a bit heavier than vanilla.

A direct check: of the 7,751 block-only voter-events across the 800 slots, 67 (0.86%) involve compounded validators. The active-validator baseline is 0.47% compounded. So the block-only side is mildly enriched in compounded validators (factor of about 1.8) but the absolute share is still well under 1%. The largest single-slot weight delta is 22,229 ETH on slot 13,285,305, which has 642 block-only voters; that is the same slot driving the worst Jaccard.

Weight follows count closely enough that the count picture holds.

### When dropping sentries

The 5 sentries do not contribute equally. Each utility sentry (`utility-mainnet-lighthouse-geth-001` and `-003`) was up for every one of the 800 slots and observed at least one aggregate from every one of the 64 committees in every slot. They did not observe every validator: each utility sentry alone captures about 99.97% of the validators that the canonical block records as voting for the head, with a mean shortfall of ~9.7 voters per slot. The other 3 sentries (`xatu-sentry-sfo3-mainnet-lighthouse-nethermind-1d`, `xatu-tysm-ams3-mainnet-003-subnets-0-1`, `xatu-tysm-ams3-mainnet-005-subnets-0-1`) only emitted aggregate-and-proof rows for 255 of the 800 slots (32%). When they were up, they also covered every committee, but their voter sets were a subset of the utility sentries'.

<ECharts config={sentryCumulativeConfig} height="280px" />

| Sentry subset | Mean voters in union | Mean Jaccard vs block | Mean `block_only` |
|---|---:|---:|---:|
| utility-001 alone | 30,186.8 | 0.99968 | 9.7 |
| utility-003 alone | 30,186.8 | 0.99968 | 9.7 |
| utility-001 + 003 (2) | 30,186.8 | 0.99968 | 9.7 |
| subnet-attached only (3) | 9,774.1 | 0.32238 | 20,422 |
| all 5 sentries | 30,186.8 | 0.99968 | 9.7 |

A single utility sentry delivers the same gossip-pool view that all 5 sentries deliver in aggregate. The second utility sentry adds nothing (their voter sets are identical when both are up). The 3 subnet-attached sentries add nothing on top of the utilities; they are a strict subset of what either utility sees. The "5-sentry pipeline" is operationally a 1-sentry pipeline as long as either utility is up. Note that this 1-utility-sentry view still falls short of the block-included view by ~9.7 voters per slot, so being inside one utility sentry's voter set is not the same as being inside the canonical chain.

If the gossip pipeline ran with only the 3 subnet-attached sentries, the picture flips: mean Jaccard against block-included falls to 0.32, mean block-only count is 20,422 per slot. That is because those 3 sentries were only up for 1 in 3 slots in this window; for the other slots the gossip-pool view is empty.

So the gossip-pool view in this window is really a 2-sentry view with 3 mostly-redundant standbys. If the two utility sentries had been down at the same time, the gossip side would have been silent for hundreds of slots in the disagreement window.

### When splitting disagreement vs agreement slots

Are the source deltas different on slots where FCR itself disagreed? The previous investigation already pinned the implementation gap to logic, not data, so we shouldn't expect much. This is the confirming check.

| Metric | Disagreement slots (n=400) | Agreement slots (n=400) |
|---|---:|---:|
| mean count delta (block − gossip) | 10.1 | 9.3 |
| mean weight delta (ETH) | 413 | 362 |
| p75 count delta | 4 | 3 |
| p90 count delta | 15 | 11 |
| mean Jaccard | 0.99966 | 0.99970 |

Disagreement slots have a slightly larger source delta (about 0.8 more block-only voters on average, or 50 ETH of weight) but the distributions overlap heavily. The two are heavily skewed with a thin tail and the means are within noise of each other. The source delta is not what carved the 2,388-slot disagreement; the `support_discount` term from the previous investigation is still the actual driver.

### When asking why gossip falls short

A natural follow-up: if a single utility sentry sees every committee yet still misses ~10 voters per slot, what specifically does the sentry miss? Two gossipsub topics carry attestation data on mainnet:

- `beacon_aggregate_and_proof`: designated aggregators broadcast a single aggregate per committee
- `beacon_attestation_<subnet>`: every validator broadcasts their individual attestation on their committee's subnet

The Teku replay uses only the aggregate-and-proof topic. A subscriber to that topic only sees a validator's vote if (a) an aggregator was selected that included that validator and (b) that aggregator's gossip message reached the sentry. Block proposers subscribe to both topics and additionally pull from their full peer mempool, so they catch every validator.

A five-slot check on the same 5 sentries hinted that switching to `libp2p_gossipsub_beacon_attestation` closes the gap. To make that conclusion stick, we re-ran the comparison on 1,995 sampled slots spread across the disagreement window (every ~98th slot, December 6 2025 to January 2 2026), pulled per-validator first-seen times from the subnet topic, decoded `aggregation_bits` from `libp2p_gossipsub_aggregate_and_proof` against `canonical_beacon_committee`, and lined the three sets up per slot.

Per slot, mean validators voting canonical head:

| Source | Mean | Median | p90 | p99 | Per-slot gap vs block (mean) |
|---|---:|---:|---:|---:|---:|
| Block-included | 30,640 | 30,796 | 30,951 | 31,005 | (baseline) |
| Subnet single-attestation (5 sentries) | 30,580 | 30,766 | 30,948 | 31,004 | 59.2 |
| Aggregate-and-proof (5 sentries) | 30,632 | 30,790 | 30,949 | 30,999 | 8.1 |

Aggregate-and-proof on the larger sample still trails block-included by 8.1 voters per slot on average (p90 = 8 voters, p99 = 153). The block-minus-subnet number is dominated by 165 slots where the subnet stream had a broad outage (mean 59.2 includes a max of 30,611). On the remaining 1,830 "clean" slots the block-minus-subnet mean is 3.1 voters per slot vs block-minus-agg 8.4 voters. So in the typical slot the subnet topic does close most of the gap; the 5-slot finding holds at scale.

The mechanism question is the new one. Of the ~8 agg-misses per slot, why didn't the aggregate-and-proof gossip cover them? Three candidate hypotheses:

1. **Late subnet arrival.** The validator's subnet attestation arrived after the 8-second aggregation deadline (4s into the slot for the attestation, 8s into the slot for the aggregator to publish). The aggregator on duty for that subnet had nothing to include.
2. **Aggregator gossip never reached us.** The validator's subnet attestation was on time, an aggregator covered it, but the resulting aggregate-and-proof message never reached any of the 5 sentries.
3. **Aggregator didn't include them.** The validator was on time on the subnet, but the chosen aggregator built an aggregate that omitted them (e.g. it picked an earlier overlapping aggregate to gossip).

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

The two distributions barely overlap. Hits cluster in the 3 to 6 second window where validators are *supposed* to attest. Misses cluster after the 8-second aggregation deadline.

| Threshold | % of agg-hits past | % of agg-misses past |
|---|---:|---:|
| > 4,000 ms | 59.17% | 100.00% |
| > 6,000 ms | 4.37% | 97.87% |
| > 8,000 ms | 0.05% | **93.63%** |
| > 12,000 ms | 0.02% | 8.87% |
| > 16,000 ms | 0.01% | 3.83% |

93.6% of the agg-misses with timing data arrived on the subnet *after* the 8-second aggregation deadline. Only 6.4% (1,022 of 16,049) arrived in time and still failed to make any aggregate-and-proof message we observed. A further 189 agg-misses across the 1,995 slots never appeared on the subnet at any sentry yet were still in the canonical block, which is the only fragment that could be hypothesis 2 or 3 (and the count is tiny: 0.1 per slot).

The verdict: hypothesis 1 wins by an order of magnitude. The bulk of validators that block-included captures but aggregate-and-proof gossip misses are validators whose own subnet attestation arrived too late for an aggregator to include in the on-time aggregate. Block proposers can scoop these up because their inclusion window extends to the next slot's proposal; an aggregate-and-proof subscriber cannot.

This sharpens the topic-choice claim from the 5-slot check. Switching to the single-attestation topic doesn't just see "more" voters; it sees the validators who showed up to vote between 8 and 12 seconds into the slot, after the aggregator deadline closed. A block proposer's view is closer to "subnet attestation, no time bound" than to "aggregate-and-proof gossip". For replaying live aggregator-and-proof behavior the agg topic is the right source; for matching what makes it into the canonical block the subnet topic is the right source.

</Section>

<Section type="takeaways">

## Takeaways

- The ~10-voters-per-slot block-included surplus over aggregate-and-proof gossip is **dominated by late subnet arrivals**, not by sentry coverage or gossip-mesh failures. Across 1,995 sampled slots and 16,049 agg-miss validators with subnet timing, 93.6% arrived on the subnet *after* the 8-second aggregation deadline. The aggregators on duty had nothing to include; block proposers picked these up later because their inclusion window extends into the next slot.
- Switching to the single-attestation gossip topic (`libp2p_gossipsub_beacon_attestation`) with the same 5 sentries closes most of the gap. On the 1,830 slots without broad subnet outages, block-minus-subnet falls to 3.1 voters per slot vs block-minus-agg 8.4. A subnet subscriber sees the late attesters that an aggregate-and-proof subscriber cannot.
- Within the aggregate-and-proof-only world, the gossip pipeline in this window is effectively a 1-sentry pipeline. Either utility sentry alone gives mean Jaccard 0.99968 against block-included. The 3 subnet-attached sentries were only up for a third of slots and add nothing when the utilities are up. The second utility sentry also adds nothing.
- Weight-by-effective-balance tracks the count delta closely. Median delta is 32 ETH = 1 plain validator. Compounded validators are mildly over-represented among block-only (0.86% vs 0.47% baseline) but the absolute share is small enough that the weight picture matches the count picture.
- Disagreement slots show a marginally larger source delta than agreement slots (mean 10.1 vs 9.3 block-only voters) but the distributions overlap heavily. The data-source gap is not what carved the FCR implementation disagreement, and the gap itself is now traceable: aggregate-and-proof gossip is a structurally on-time view; block-included and single-attestation gossip are not.

</Section>
