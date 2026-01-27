---
title: Snooper Overhead on get_blobs
sidebar_position: 3
description: Measuring the latency impact of rpc-snooper on get_blobs calls between CL and EL on 7870 reference nodes
date: 2026-01-16T00:00:00Z
author: samcm
tags:
  - snooper
  - engine-api
  - get-blobs
  - latency
  - 7870
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-16T00:00:00Z"
    author="samcm"
    tags={["snooper", "engine-api", "get-blobs", "latency", "7870"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-15T00:00:00Z"
    endTime="2026-01-16T23:59:59Z"
/>

```sql end_to_end
select * from xatu.snooper_end_to_end_comparison
```

```sql overhead_by_client
select * from xatu.snooper_overhead_by_client
```

```sql overhead_by_blobs
select * from xatu.snooper_overhead_by_blobs
```

<Section type="question">

## Question

What is the latency impact of rpc-snooper on `get_blobs` calls between the consensus layer and execution layer?

</Section>

<Section type="background">

## Background

On January 16, 2026, we deployed [rpc-snooper](https://github.com/ethpandaops/rpc-snooper) to the 7870 mainnet reference nodes. The snooper sits between the consensus layer (CL) and execution layer (EL), intercepting Engine API calls to capture detailed timing data.

This investigation measures:
1. **End-to-end impact** - Does adding a proxy affect CL-perceived latency?
2. **Internal overhead** - How much time does serialization/deserialization add?

### Data Sources

- `consensus_engine_api_get_blobs` - Timing from Prysm's perspective (CL side)
- `execution_engine_get_blobs` - Timing from the snooper (EL side)

The difference between these represents the snooper's serialization overhead.

</Section>

<Section type="investigation">

## Investigation

### End-to-End Impact

Comparing what Prysm observed on **January 15** (direct CL→EL) vs **January 16** (CL→snooper→EL).

<SqlSource source="xatu" query="snooper_end_to_end_comparison" />

<DataTable
    data={end_to_end}
    rows=10
>
    <Column id="el_client" title="EL Client" />
    <Column id="jan15_no_snooper_ms" title="Jan 15 (No Snooper)" fmt="num1" contentType="colorscale" scaleColor="#10b981" />
    <Column id="jan16_with_snooper_ms" title="Jan 16 (With Snooper)" fmt="num1" contentType="colorscale" scaleColor="#3b82f6" />
    <Column id="delta_ms" title="Delta (ms)" fmt="num1" />
    <Column id="delta_pct" title="Delta (%)" fmt="pct1" />
</DataTable>

<BarChart
    data={end_to_end}
    x=el_client
    y={["jan15_no_snooper_ms", "jan16_with_snooper_ms"]}
    type=grouped
    title="End-to-End Latency Comparison"
    chartAreaHeight=300
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'EL Client', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Duration (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

The snooper adds negligible end-to-end latency. Most clients show less than 5% difference between direct and proxied connections. Some variance is expected due to different blob counts and network conditions between days.

### Internal Overhead by EL Client

Measuring the actual serialization cost by comparing EL-side timing (from snooper) to CL-side timing (from Prysm).

<SqlSource source="xatu" query="snooper_overhead_by_client" />

<DataTable
    data={overhead_by_client}
    rows=10
>
    <Column id="el_client" title="EL Client" />
    <Column id="calls" title="Calls" fmt="num0" />
    <Column id="total_blobs" title="Total Blobs" fmt="num0" />
    <Column id="avg_overhead_ms" title="Avg Overhead (ms)" fmt="num1" contentType="colorscale" scaleColor="#f59e0b" />
    <Column id="p50_overhead_ms" title="P50 (ms)" fmt="num0" />
    <Column id="p95_overhead_ms" title="P95 (ms)" fmt="num0" />
    <Column id="overhead_per_blob_ms" title="Per Blob (ms)" fmt="num1" contentType="colorscale" scaleColor="#ef4444" />
</DataTable>

<BarChart
    data={overhead_by_client}
    x=el_client
    y=overhead_per_blob_ms
    title="Serialization Overhead per Blob by EL Client"
    chartAreaHeight=300
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'EL Client', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Overhead (ms/blob)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

Per-blob overhead varies significantly by client:
- **nethermind** has the lowest per-blob overhead (~3.9ms)
- **besu** has the highest per-blob overhead (~11.8ms)
- Average across all clients: **~7ms per blob**

### Overhead by Blob Count

How does serialization overhead scale with the number of blobs in a `get_blobs` call?

<SqlSource source="xatu" query="snooper_overhead_by_blobs" />

<LineChart
    data={overhead_by_blobs}
    x=blob_count
    y=overhead_ms
    markers=true
    sort=true
    title="Total Serialization Overhead by Blob Count"
    chartAreaHeight=300
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'Blob Count', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Total Overhead (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

<LineChart
    data={overhead_by_blobs}
    x=blob_count
    y=per_blob_ms
    markers=true
    sort=true
    title="Per-Blob Overhead by Blob Count"
    chartAreaHeight=300
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'Blob Count', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Per Blob Overhead (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

Total overhead scales roughly linearly with blob count, while per-blob overhead remains fairly consistent at 6-7ms per blob.

</Section>

<Section type="takeaways">

## Takeaways

- The snooper adds **negligible end-to-end latency** - most clients show less than 5% difference
- Serialization overhead is approximately **6-7ms per blob** on average
- For a typical 6-blob block: ~45ms serialization overhead
- **nethermind** has the lowest per-blob overhead (~3.9ms), while **besu** has the highest (~11.8ms)
- The overhead is acceptable for production use and gives us Engine API visibility we didn't have before

</Section>
