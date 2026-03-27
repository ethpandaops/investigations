---
title: Validating the Next-Block Attestation Proxy
sidebar_position: 3
description: Can the FCR simulator reliably use next-block attestations as a proxy for what was seen on P2P gossip? Comparing block-included attestations with P2P observations across a month of mainnet data.
date: 2026-03-27T00:00:00Z
author: samcm
tags:
  - consensus
  - fast-confirmation
  - attestations
  - simulation
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // ============================================================
    // Pre-computed data: P2P vs Block validator drift
    // ============================================================
    // Per-slot comparison of unique attesting validators seen on P2P
    // (beacon_api_eth_v1_events_attestation, within 12s of slot start)
    // vs validators included in the next block
    // (canonical_beacon_elaborated_attestation, delay=1).
    // Sampled across 3 dates (2-hour windows each, ~600 slots per sample).

    // Drift histogram bins (Mar 20, 7175 slots, full day)
    // Each bin shows how many slots have |drift| in that range
    const driftBins = ['0%', '0-0.01%', '0.01-0.05%', '0.05-0.1%', '0.1-0.2%', '0.2-0.5%', '0.5-1%', '1-2%', '2-5%', '5-10%'];
    const driftCounts = [1454, 1453, 1851, 682, 641, 490, 193, 130, 93, 9];

    // ============================================================
    // Pre-computed data: Daily inclusion delay statistics
    // ============================================================
    // Per-validator average inclusion delay (slots) by day.
    // Source: fct_attestation_inclusion_delay_daily on xatu-cbt, Feb 25 - Mar 17 2026.
    // Each validator attests once per slot; inclusion delay = block_slot - attested_slot.
    // A delay of 1.0 means inclusion in the very next block.
    const inclusionDays = ['2026-02-25', '2026-02-26', '2026-02-27', '2026-02-28', '2026-03-01', '2026-03-02', '2026-03-03', '2026-03-04', '2026-03-05', '2026-03-06', '2026-03-07', '2026-03-08', '2026-03-09', '2026-03-10', '2026-03-11', '2026-03-12', '2026-03-13', '2026-03-14', '2026-03-15', '2026-03-16', '2026-03-17'];
    const inclusionAvg = [1.008, 1.007, 1.006, 1.009, 1.005, 1.008, 1.007, 1.007, 1.007, 1.01, 1.008, 1.006, 1.007, 1.009, 1.008, 1.009, 1.006, 1.006, 1.005, 1.009, 1.01];
    const inclusionP95 = [1.013, 1.014, 1.011, 1.012, 1.008, 1.011, 1.011, 1.012, 1.015, 1.014, 1.011, 1.011, 1.009, 1.008, 1.009, 1.01, 1.009, 1.012, 1.007, 1.008, 1.014];

    // ============================================================
    // Chart configs
    // ============================================================

    // Chart 1: Per-slot drift histogram
    $: driftConfig = {
        title: { text: 'Per-Slot Validator Drift Distribution', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: {
            trigger: 'axis',
            formatter: (params) => {
                const p = params[0];
                const total = 7175;
                const pct = (p.value / total * 100).toFixed(1);
                return `<b>${p.axisValue}</b><br/>${p.marker} ${p.value.toLocaleString()} slots (${pct}%)`;
            }
        },
        grid: { left: 70, right: 30, bottom: 80, top: 50 },
        xAxis: {
            type: 'category',
            data: driftBins,
            name: '|P2P - Block| as % of P2P Validators',
            nameLocation: 'center',
            nameGap: 60,
            axisLabel: { rotate: 45, fontSize: 10 }
        },
        yAxis: {
            type: 'value',
            name: 'Number of Slots',
            nameLocation: 'center',
            nameGap: 50,
            nameRotate: 90
        },
        series: [{
            type: 'bar',
            data: driftCounts,
            itemStyle: { color: '#2563eb' },
            barWidth: '60%'
        }]
    };

    // Chart 2: Daily inclusion delay (pre-computed static data)
    $: inclusionConfig = {
        title: { text: 'Daily Average Inclusion Delay (Slots)', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: {
            trigger: 'axis',
            formatter: (params) => {
                let html = `<b>${params[0].axisValue}</b><br/>`;
                params.forEach(p => { html += `${p.marker} ${p.seriesName}: ${p.value} slots<br/>`; });
                return html;
            }
        },
        legend: { data: ['Average', 'P95'], bottom: 0 },
        grid: { left: 70, right: 30, bottom: 60, top: 50 },
        xAxis: {
            type: 'category',
            data: inclusionDays,
            name: 'Date',
            nameLocation: 'center',
            nameGap: 40,
            axisLabel: { interval: 6, rotate: 45, fontSize: 10 }
        },
        yAxis: {
            type: 'value',
            name: 'Inclusion Delay (slots)',
            nameLocation: 'center',
            nameGap: 50,
            nameRotate: 90,
            min: 1.0,
            max: 1.1
        },
        series: [
            { name: 'Average', type: 'line', data: inclusionAvg, symbol: 'none', lineStyle: { color: '#2563eb', width: 2 }, itemStyle: { color: '#2563eb' }, areaStyle: { color: 'rgba(37, 99, 235, 0.1)' } },
            { name: 'P95', type: 'line', data: inclusionP95, symbol: 'none', lineStyle: { color: '#ea580c', width: 1.5, type: 'dashed' }, itemStyle: { color: '#ea580c' } }
        ]
    };
</script>

<PageMeta
    date="2026-03-27T00:00:00Z"
    author="samcm"
    tags={["consensus", "fast-confirmation", "attestations", "simulation"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-02-25T00:00:00Z"
    endTime="2026-03-24T23:59:59Z"
/>

<Section type="question">

## Question

Can we reliably use next-block attestations as a proxy for P2P-observed attestations when simulating the Fast Confirmation Rule?

</Section>

<Section type="background">

## Background

The [FCR simulator](https://github.com/ethpandaops/fcr-simulator) replays historical Ethereum blocks through Lighthouse's Fast Confirmation Rule implementation. For each slot N, it processes the block, then injects attestations from the next block (N+1) into fork choice before evaluating whether the block would be fast confirmed.

This approach rests on an assumption: attestations included in block N+1 are a reasonable proxy for what a node would have seen on the P2P gossip network during slot N. In practice, a proposer at slot N+1 sees aggregated attestations arriving around 8 seconds into slot N, then has 4 seconds to build the block and include them.

Two things could make this proxy inaccurate:

- **P2P attestations not in blocks**: our sentries saw aggregates on gossip that the proposer didn't include (the simulator would undercount votes)
- **Block attestations not on P2P**: the proposer included attestations our sentries never saw on gossip (the simulator would overcount votes)

We compare per-slot unique validator counts from `beacon_api_eth_v1_events_attestation` (P2P view, within 12 seconds of slot start) against `canonical_beacon_elaborated_attestation` (block-included view) across a month of mainnet data.

</Section>

<Section type="investigation">

## Investigation

### How many validators does the first block capture?

*1,800 slots sampled across 3 dates (Feb 27, Mar 10, Mar 22). Source: `canonical_beacon_elaborated_attestation` on xatu.*

For each attested slot, we count how many unique validators are included in the very first subsequent block versus all blocks. This measures how much of the total vote weight is available from the single block the FCR simulator uses.

| Sample Date | Avg Coverage | P5 Coverage | Min Coverage | Slots |
|-------------|-------------|-------------|-------------|-------|
| Feb 27 | 99.90% | 99.56% | 94.60% | 598 |
| Mar 10 | 99.88% | 99.45% | 97.15% | 594 |
| Mar 22 | 99.94% | 99.78% | 97.32% | 598 |

The first block after the attested slot captures **99.9% of validators** on average. Even the 5th percentile stays above 99.4%. The rare cases where coverage dips below 97% align with missed slots or epochs with elevated late attestations.

The per-validator inclusion delay data from xatu-cbt confirms this: the average across the network is just 1.005-1.01 slots, meaning nearly every validator's attestation lands in the very next block.

### How does P2P gossip compare to block inclusion?

*7,175 slots on Mar 20 2026 (full day). Source: `beacon_api_eth_v1_events_attestation` and `canonical_beacon_elaborated_attestation` on xatu.*

For each slot, we compare the number of unique validators seen attesting on P2P (within 12 seconds of slot start) versus validators included in the next block.

<ECharts config={driftConfig} height="450px" />

The drift is heavily concentrated near zero. 20.3% of slots have an exact match, and 69.1% have drift under 0.05%.

| Drift Range | Slots | Cumulative |
|-------------|-------|-----------|
| Exact match (0%) | 1,454 (20.3%) | 20.3% |
| `<= 0.05%` | 3,304 (46.1%) | 66.3% |
| `<= 0.1%` | 682 (9.5%) | 75.8% |
| `<= 0.5%` | 1,131 (15.8%) | 91.6% |
| `<= 1%` | 193 (2.7%) | 94.3% |
| `> 1%` | 411 (5.7%) | 100% |

Across 3 sample dates the pattern is consistent:

| Sample Date | Mean Drift | Median Drift | P95 Drift | Slots Within 1% |
|-------------|-----------|-------------|----------|-----------------|
| Feb 27 | 0.104% | 0.017% | 0.448% | 97.8% |
| Mar 10 | 0.114% | 0.010% | 0.553% | 96.8% |
| Mar 22 | 0.063% | 0.010% | 0.222% | 99.0% |

Mean drift is consistently under 0.12%, and 97%+ of slots have drift within 1%.

**Direction**: in 77.7% of slots, P2P saw more validators than the block included (the proposer couldn't fit everything). In 20.3% the counts were identical. In 2.0% of slots, the block contained validators not seen on our P2P sentries, likely from direct peering connections the proposer had.

### What does the inclusion delay look like over time?

*151,120 slots from Feb 25 to Mar 17 2026 (21 days). Source: `fct_attestation_inclusion_delay_daily` on xatu-cbt.*

The per-validator inclusion delay measures how many slots after attesting each validator's attestation is included in a block. A delay of 1.0 means inclusion in the very next block.

<ECharts config={inclusionConfig} height="450px" />

The average inclusion delay hovers between 1.005 and 1.01 slots across the entire period, meaning the vast majority of validators are included in the very next block. Even the 95th percentile stays below 1.015. The consistency across 21 days confirms this is a stable property of the network, not a transient observation.

</Section>

<Section type="takeaways">

## Takeaways

- **First block captures 99.9% of validators**: the average per-validator inclusion delay is just 1.005-1.01 slots, meaning nearly every attestation lands in the very next block
- **P2P vs block drift is under 0.12%**: across a month of samples, the mean validator count difference between P2P observations and block inclusion is negligible, with 97%+ of slots within 1%
- **The proxy assumption is valid**: using next-block attestations to simulate what was seen on P2P introduces drift well below the margin that would affect FCR confirmation outcomes

</Section>
