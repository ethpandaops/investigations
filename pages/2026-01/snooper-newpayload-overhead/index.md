---
title: Snooper Overhead on newPayload
sidebar_position: 3
description: Measuring the serialization overhead of rpc-snooper on engine_newPayload calls on 7870 reference nodes
date: 2026-01-27T12:00:00Z
author: samcm
tags:
  - snooper
  - engine-api
  - new-payload
  - latency
  - 7870
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: distributionConfig = {
        title: { text: 'Overhead Distribution', left: 'center' },
        tooltip: { trigger: 'axis' },
        grid: { left: 80, right: 30, bottom: 80, top: 60 },
        xAxis: {
            type: 'category',
            data: newpayload_distribution?.map(d => d.overhead_range) || [],
            name: 'Overhead Range (ms)',
            nameLocation: 'center',
            nameGap: 60,
            axisLabel: { rotate: 45, fontSize: 10 }
        },
        yAxis: {
            type: 'value',
            name: 'Percentage of Calls',
            nameLocation: 'center',
            nameGap: 50,
            nameRotate: 90,
            axisLabel: { formatter: '{value}%' }
        },
        series: [{
            data: newpayload_distribution?.map(d => d.pct) || [],
            type: 'bar',
            itemStyle: { color: '#2563eb' }
        }]
    };

    $: overheadByClientConfig = (() => {
        if (!newpayload_end_to_end || newpayload_end_to_end.length === 0) return {};

        const clients = newpayload_end_to_end.map(d => d.el_client);

        return {
            title: { text: 'newPayload Overhead by EL Client', left: 'center' },
            tooltip: { trigger: 'axis' },
            legend: { data: ['Average', 'P50', 'P95'], right: 10, orient: 'vertical', top: 'center' },
            grid: { left: 80, right: 120, bottom: 80, top: 60 },
            xAxis: {
                type: 'category',
                data: clients,
                name: 'EL Client',
                nameLocation: 'center',
                nameGap: 60,
                axisLabel: { rotate: 45, fontSize: 10 }
            },
            yAxis: {
                type: 'value',
                name: 'Overhead (ms)',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90
            },
            series: [
                {
                    name: 'Average',
                    type: 'bar',
                    data: newpayload_end_to_end.map(d => d.avg_overhead_ms),
                    itemStyle: { color: '#2563eb' }
                },
                {
                    name: 'P50',
                    type: 'bar',
                    data: newpayload_end_to_end.map(d => d.p50_overhead_ms),
                    itemStyle: { color: '#16a34a' }
                },
                {
                    name: 'P95',
                    type: 'bar',
                    data: newpayload_end_to_end.map(d => d.p95_overhead_ms),
                    itemStyle: { color: '#dc2626' }
                }
            ]
        };
    })();

</script>

<PageMeta
    date="2026-01-27T12:00:00Z"
    author="samcm"
    tags={["snooper", "engine-api", "new-payload", "latency", "7870"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-26T00:00:00Z"
    endTime="2026-01-26T23:59:59Z"
/>

```sql newpayload_end_to_end
select * from xatu.snooper_newpayload_end_to_end
```

```sql newpayload_distribution
select * from xatu.snooper_newpayload_overhead_distribution
```

<Section type="question">

## Question

What is the serialization overhead of rpc-snooper on `engine_newPayload` calls, and is the overhead consistent across EL clients?

</Section>

<Section type="background">

## Background

The [rpc-snooper](https://github.com/ethpandaops/rpc-snooper) is deployed on the 7870 mainnet reference nodes. It sits between the consensus layer (CL) and execution layer (EL), intercepting Engine API calls to capture timing data.

![Snooper architecture: CL → rpc-snooper → EL, showing CL-observed duration vs EL-observed duration](/images/snooper-newpayload-architecture.jpg)

Here we're looking at `engine_newPayload` — where the CL sends a new execution payload to the EL for validation. We already measured [get_blobs overhead](/2026-01/snooper-overhead/) separately. Since `newPayload` involves heavier EL-side processing (block execution), the snooper's relative overhead should be smaller here.

### Methodology

Since the 7870 nodes report to both tables, we can measure overhead on a **per-slot basis** by joining the CL-side and EL-side observations of the same `newPayload` call on the same block:

- **`consensus_engine_api_new_payload`** — Duration as observed by the CL (CL → snooper → EL → snooper → CL)
- **`execution_engine_new_payload`** — Duration as observed by the snooper (snooper → EL → snooper), filtered to `source = 'ENGINE_SOURCE_SNOOPER'`

For each matched block, **overhead = CL duration - EL duration**.

</Section>

<Section type="investigation">

## Investigation

### When Comparing Across Clients

Per-client summary of the snooper overhead across ~67,800 matched slots on January 26.

<SqlSource source="xatu" query="snooper_newpayload_end_to_end" />

<DataTable
    data={newpayload_end_to_end}
    rows=10
>
    <Column id="el_client" title="EL Client" />
    <Column id="slots" title="Matched Slots" fmt="num0" />
    <Column id="avg_cl_ms" title="CL Duration (ms)" fmt="num1" contentType="colorscale" scaleColor="#3b82f6" />
    <Column id="avg_el_ms" title="EL Duration (ms)" fmt="num1" contentType="colorscale" scaleColor="#10b981" />
    <Column id="avg_overhead_ms" title="Avg Overhead (ms)" fmt="num1" contentType="colorscale" scaleColor="#f59e0b" />
    <Column id="p50_overhead_ms" title="P50 (ms)" fmt="num1" />
    <Column id="p95_overhead_ms" title="P95 (ms)" fmt="num1" />
    <Column id="p99_overhead_ms" title="P99 (ms)" fmt="num1" />
    <Column id="overhead_pct" title="Overhead %" fmt="num1" />
</DataTable>

<ECharts config={overheadByClientConfig} height="500px" />

P50 overhead is 4-5ms across all EL clients. Erigon's mean looks high (17.9ms) but that's 23 extreme outliers (up to 7.8s) out of 13,572 calls pulling it up. Its trimmed average is 5.1ms, same as everything else. The overhead is a fixed serialization cost — it doesn't depend on what the EL is doing.

Slower clients feel it less: Erigon at ~427ms avg only loses ~4% to the snooper, while Reth at ~54ms avg loses ~10%.

### When Looking at the Distribution

How the serialization overhead is distributed across all `newPayload` calls.

<SqlSource source="xatu" query="snooper_newpayload_overhead_distribution" />

<ECharts config={distributionConfig} height="500px" />

~81% of all calls fall in the 2-10ms range. The 4-6ms bucket is the most common at ~34%. Less than 1% of calls exceed 20ms.

</Section>

<Section type="takeaways">

## Takeaways

- Median overhead is 4-5ms for `engine_newPayload`, regardless of EL client
- It's a fixed serialization cost that doesn't scale with payload size or EL processing time
- 81% of calls land in the 2-10ms range; less than 1% exceed 20ms
- Erigon has rare extreme outliers that inflate its mean, but its P50 is the same as everyone else
- Relative impact: ~4% on slow clients (Erigon) up to ~10% on fast clients (Reth)
- Together with the [get_blobs results](/2026-01/snooper-overhead/), the snooper is fine for production on reference nodes

</Section>
