---
title: Proposer Mempool Omissions on Mainnet
sidebar_position: 1
description: Tests whether Ethereum mainnet proposer entities persistently omit high-priority public mempool transactions after accounting for builders and transaction validity.
date: 2026-07-13T06:15:00Z
author: samcm
tags:
  - mempool
  - censorship
  - transaction-inclusion
  - mev-boost
  - builders
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-07-13T06:15:00Z"
    author="samcm"
    tags={["mempool", "censorship", "transaction-inclusion", "mev-boost", "builders"]}
    description="Tests whether Ethereum mainnet proposer entities persistently omit high-priority public mempool transactions after accounting for builders and transaction validity."
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-13T00:00:00Z"
    endTime="2026-07-12T00:00:00Z"
/>

```sql headline
SELECT
    sum(blocks) AS blocks,
    sum(selected) AS selected,
    sum(omitted) AS omitted,
    sum(opportunities) AS opportunities,
    round(100 * sum(omitted) / sum(opportunities), 3) AS omission_pct
FROM static.proposer_mempool_period
```

```sql period_trend
SELECT *
FROM static.proposer_mempool_period
ORDER BY period ASC
```

```sql relay_summary
SELECT *
FROM static.proposer_mempool_relay
ORDER BY relay_observed ASC
```

```sql proposer_overview
SELECT *
FROM static.proposer_mempool_entities
WHERE opportunities >= 50000
ORDER BY builder_adjusted_ratio DESC
LIMIT 15
```

```sql proposer_signals
SELECT *
FROM static.proposer_mempool_entity_period
WHERE proposer_entity IN ('upbit', 'gateway.fmas_lido', 'figment_lido', 'kraken', 'solo_stakers')
ORDER BY period ASC, proposer_entity ASC
```

```sql persistence_screen
SELECT
    count(*) AS qualifying_entities,
    max(periods_over_1_5) AS most_periods_over_1_5,
    count(*) FILTER (WHERE periods_over_1_5 >= 4) AS persistent_entities,
    count(*) FILTER (WHERE periods_over_2 >= 4) AS persistent_entities_over_2
FROM static.proposer_mempool_entities
WHERE qualifying_periods >= 4
```

```sql builder_spread
SELECT *
FROM static.proposer_mempool_builders
WHERE opportunities >= 100000
ORDER BY omission_pct DESC
```

```sql target_screen
SELECT
    count(*) AS tested_signatures,
    count(*) FILTER (WHERE consistent_elevation) AS consistent_elevation_signatures,
    count(*) FILTER (WHERE recurring_high_rate) AS recurring_high_rate_signatures
FROM static.proposer_mempool_targets
```

```sql target_bursts
SELECT *
FROM static.proposer_mempool_target_top
ORDER BY omitted DESC
LIMIT 10
```

```sql observer_crosscheck
SELECT *
FROM static.proposer_mempool_observers
ORDER BY sample_date ASC
```

<Section type="question">

## Question

Is there evidence that Ethereum mainnet proposer entities consistently censored public mempool transactions between 13 January and 12 July 2026?

</Section>

<Section type="background">

## Background

A transaction being present in a public mempool but absent from the next block is not, by itself, evidence of censorship. The winning block producer may not have received it, the transaction may depend on an earlier nonce, its fee may be uncompetitive, or it may not fit in the remaining block gas.

Proposer-builder separation adds another attribution problem. When a proposer accepts an MEV-Boost payload, a builder has already selected and ordered the transactions. The proposer chooses a completed payload, not individual transactions inside it. This investigation therefore separates proposer entities from observed builder pubkeys and treats omission as a screening signal rather than proof of intent.

The fixed window is **13 January 2026 00:00 UTC to 12 July 2026 00:00 UTC**, split into six 30-day periods. The primary mempool source ends at 11 July 2026 23:59:59.900 UTC, so the final roughly 36 hours before publication are not included.

All page queries read immutable Parquet snapshots from `data.ethpandaops.io`; rebuilding this page does not repeat the ClickHouse scans. The snapshot contains aggregates derived from 235,952,025 mempool records and 1,288,629 canonical blocks.

</Section>

<Section type="investigation">

## Investigation

### When defining a conservative omission

A transaction counts as a strict omission candidate for decision block `B` only when it:

1. was publicly observed at least **8 seconds before** `B`;
2. was included in the immediately following canonical slot, `B + 1`;
3. could pay `B`'s base fee;
4. offered an effective priority fee at or above the **75th percentile** of transactions selected for `B`;
5. had a gas limit no greater than the unused gas remaining at the end of `B`; and
6. had no observable lower-nonce dependency in `B` or before it in `B + 1`.

The effective priority fee is `min(maxPriorityFee, maxFee - baseFee)` for EIP-1559 transactions and `gasPrice - baseFee` for legacy transactions. The denominator contains similarly public, high-priority transactions that were selected for `B`.

<SqlSource source="static" query="proposer_mempool_period" />

<DataTable data={headline} rows=1>
    <Column id="blocks" title="Canonical blocks" fmt="num0" />
    <Column id="opportunities" title="Decision opportunities" fmt="num0" />
    <Column id="omitted" title="Strict omissions" fmt="num0" />
    <Column id="omission_pct" title="Omission proxy (%)" fmt="num3" />
</DataTable>

The resulting dataset contains **23,870,222** decision opportunities. **723,971** meet the strict omission definition, an aggregate proxy rate of **3.033%**. These are candidate selection misses, not 723,971 censorship events.

### When comparing 30-day periods

<SqlSource source="static" query="proposer_mempool_period" />

<LineChart
    data={period_trend}
    x="period_label"
    y="omission_pct"
    title="Strict omission proxy declined across the fixed window"
    yFmt="num3"
    chartAreaHeight=400
    markers=true
    markerSize=6
    lineWidth=3
    colorPalette={['#2563eb']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 80, left: 70, top: 60, right: 30},
        xAxis: {name: '30-day period', nameLocation: 'center', nameGap: 55, axisLabel: {rotate: 20}},
        yAxis: {min: 0},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {text: 'Strict omission proxy (%)', fontSize: 12, fill: '#666'}
        }]
    }}
/>

<DataTable data={period_trend} rows=6>
    <Column id="period_label" title="Period" />
    <Column id="blocks" title="Blocks" fmt="num0" />
    <Column id="opportunities" title="Opportunities" fmt="num0" />
    <Column id="omitted" title="Strict omissions" fmt="num0" />
    <Column id="omission_pct" title="Omission proxy (%)" fmt="num3" />
</DataTable>

The network baseline fell from **4.373%** in the first period to **1.632%** in the sixth. Comparing pooled six-month rates without controlling for period would therefore misclassify entities whose blocks are unevenly distributed over time.

### When separating builders from proposers

A relay-delivered payload was observed for **92.851%** of analyzed blocks. The omission proxy is higher for those observed builder payloads than for blocks without an observed relay payload.

<SqlSource source="static" query="proposer_mempool_relay" />

<DataTable data={relay_summary} rows=2>
    <Column id="payload_classification" title="Payload classification" />
    <Column id="blocks" title="Blocks" fmt="num0" />
    <Column id="opportunities" title="Opportunities" fmt="num0" />
    <Column id="omitted" title="Strict omissions" fmt="num0" />
    <Column id="omission_pct" title="Omission proxy (%)" fmt="num3" />
</DataTable>

Among the 26 observed builder pubkeys with at least 100,000 opportunities, omission rates range from **0.133% to 4.373%**, with a median of **2.511%**. Builder choice explains a substantial share of the apparent proposer differences.

<SqlSource source="static" query="proposer_mempool_builders" />

<BarChart
    data={builder_spread}
    x="builder_short"
    y="omission_pct"
    title="High-volume builders have materially different omission rates"
    yFmt="num3"
    chartAreaHeight=450
    colorPalette={['#ea580c']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 100, left: 70, top: 60, right: 30},
        xAxis: {name: 'Builder pubkey', nameLocation: 'center', nameGap: 75, axisLabel: {rotate: 45}},
        yAxis: {min: 0},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {text: 'Strict omission proxy (%)', fontSize: 12, fill: '#666'}
        }]
    }}
/>

A missing relay record does not prove that a block was locally built, because relay coverage can be incomplete.

### When testing proposer persistence

For each proposer entity, expected omissions are calculated from its exact mix of 30-day periods and builder pubkeys. A builder-adjusted ratio of `1.0` means the entity matched that expectation. The persistence screen requires at least 1,000 opportunities in a period and checks whether an entity exceeds `1.5` times expectation in at least four periods.

<SqlSource source="static" query="proposer_mempool_entity_period" />

<LineChart
    data={proposer_signals}
    x="period_label"
    y="builder_adjusted_ratio"
    series="proposer_entity"
    title="The strongest large-entity signals are not persistent for all six periods"
    yFmt="num2"
    chartAreaHeight=450
    markers=true
    markerSize=5
    lineWidth=2
    colorPalette={['#dc2626', '#2563eb', '#9333ea', '#16a34a', '#ea580c']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 80, left: 70, top: 60, right: 145},
        xAxis: {name: '30-day period', nameLocation: 'center', nameGap: 55, axisLabel: {rotate: 20}},
        yAxis: {min: 0},
        legend: {show: true, right: 5, orient: 'vertical', top: 'center'},
        series: [{
            markLine: {
                silent: true,
                symbol: 'none',
                label: {show: true, position: 'insideEndTop', formatter: 'Expected rate'},
                lineStyle: {type: 'dashed', color: '#888'},
                data: [{yAxis: 1}]
            }
        }],
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {text: 'Observed / builder-adjusted expected', fontSize: 12, fill: '#666'}
        }]
    }}
/>

<SqlSource source="static" query="proposer_mempool_entities" />

<DataTable data={proposer_overview} rows=15>
    <Column id="proposer_entity" title="Proposer entity" />
    <Column id="opportunities" title="Opportunities" fmt="num0" />
    <Column id="omission_pct" title="Raw rate (%)" fmt="num3" />
    <Column id="builder_adjusted_ratio" title="Adjusted ratio" fmt="num3" />
    <Column id="periods_over_1_5" title="Periods above 1.5×" fmt="num0" />
    <Column id="periods_over_2" title="Periods above 2×" fmt="num0" />
</DataTable>

No qualifying entity exceeds `1.5` times its builder- and period-adjusted expectation in four or more windows. No entity exceeds twice expectation in four or more windows.

The strongest pooled large-entity result is Upbit at **1.680 times expected**, but its period ratios are `1.888`, `1.272`, `4.096`, `0.839`, `1.301`, and `0.541`. Kraken shows a weaker recent pattern: `0.948`, `0.958`, `1.610`, `1.260`, `1.343`, and `1.345`. That is worth monitoring, but it does not identify a censored transaction class.

### When looking for recurring transaction targets

The six strongest high-volume anomalies were screened by proposer entity, destination address, and first four calldata bytes: Kraken, Upbit, Figment Lido, gateway.fmas Lido, `whale_0x8b0d`, and Twinstake.

A target signature counts as consistent only if it has at least 20 opportunities in four periods, at least 20 total omissions, and an omission rate at least twice the entity baseline in four periods. A second screen checks for an absolute omission rate of at least 10% in four periods.

<SqlSource source="static" query="proposer_mempool_targets" />

<DataTable data={target_screen} rows=1>
    <Column id="tested_signatures" title="Qualified target signatures" fmt="num0" />
    <Column id="consistent_elevation_signatures" title="Consistently elevated" fmt="num0" />
    <Column id="recurring_high_rate_signatures" title="Recurring rate ≥10%" fmt="num0" />
</DataTable>

Neither screen returns a candidate. The largest destination-level anomalies are isolated bursts, including the same destination appearing under unrelated proposer entities.

<SqlSource source="static" query="proposer_mempool_target_top" />

<DataTable data={target_bursts} rows=10>
    <Column id="proposer_entity" title="Proposer entity" />
    <Column id="target" title="Destination" />
    <Column id="method" title="Method" />
    <Column id="opportunities" title="Opportunities" fmt="num0" />
    <Column id="omitted" title="Strict omissions" fmt="num0" />
    <Column id="periods" title="Periods present" fmt="num0" />
    <Column id="omission_pct" title="Omission proxy (%)" fmt="num3" />
</DataTable>

### When checking a second mempool dataset

One complete day from each 30-day period was cross-checked against Xatu's independent `mempool_transaction` observations. Of 20,934 strict candidates, **20,685 (98.811%)** appeared in Xatu. **19,988 (95.480%)** were observed before the decision block by at least two Xatu nodes in two countries.

<SqlSource source="static" query="proposer_mempool_observers" />

<LineChart
    data={observer_crosscheck}
    x="sample_date"
    y={["match_pct", "two_node_country_pct"]}
    title="Independent Xatu observers confirm most sampled candidates were public"
    yFmt="num2"
    chartAreaHeight=400
    markers=true
    markerSize=6
    lineWidth=2
    colorPalette={['#2563eb', '#16a34a']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 60, left: 70, top: 60, right: 130},
        xAxis: {name: 'Sample date', nameLocation: 'center', nameGap: 40},
        yAxis: {min: 90, max: 100},
        legend: {show: true, right: 5, orient: 'vertical', top: 'center'},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {text: 'Candidates independently observed (%)', fontSize: 12, fill: '#666'}
        }]
    }}
/>

<DataTable data={observer_crosscheck} rows=6>
    <Column id="sample_date" title="Sample date" />
    <Column id="strict_candidates" title="Strict candidates" fmt="num0" />
    <Column id="xatu_matches" title="Xatu matches" fmt="num0" />
    <Column id="match_pct" title="Matched (%)" fmt="num3" />
    <Column id="two_node_country_pct" title="Two nodes and countries (%)" fmt="num3" />
    <Column id="median_xatu_lead_ms" title="Median lead (ms)" fmt="num0" />
</DataTable>

This confirms broad public propagation for the sampled candidates. It still does not prove that the winning builder or local execution client received each transaction before its payload cutoff.

### When interpreting the result

The screen finds omission, but not convincing evidence of consistent proposer censorship. The observable patterns are dominated by changing network-wide baselines, builder differences, and short-lived traffic bursts. No proposer entity passes the persistence threshold, and no recurring destination or method signature appears among the strongest high-volume anomalies.

This result does not prove that censorship never occurred. A low-volume target, a policy producing less than a 1.5-times aggregate excess, incomplete builder visibility, account-state constraints, transaction replacement, or private bundle behavior could evade this method. Validator-to-entity labels are also incomplete: 44,972 analyzed blocks are labeled `unknown`.

</Section>

<Section type="takeaways">

## Takeaways

- **No proposer entity shows a persistent builder-adjusted omission excess across four of the six 30-day periods.**
- **No recurring destination and method signature appears among the six strongest high-volume proposer anomalies.**
- **Builder identity matters more than most proposer labels:** high-volume builder omission rates range from 0.133% to 4.373%.
- **The independent Xatu cross-check confirms that 98.811% of sampled strict candidates were publicly observed.**
- **Omission remains a screening signal, not proof of censorship or intent.**

</Section>
