---
title: Blob Mempool Propagation and Head Timing Impact
sidebar_position: 4
description: Analyzing how blob mempool propagation affects engine_getBlobsV2 success rates and per-node head timing
date: 2026-01-21
author: samcm
tags:
  - blobs
  - mev
  - engine-api
  - get-blobs
  - data-availability
  - peerDAS
  - mempool
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-21"
    author="samcm"
    tags={["blobs", "mev", "engine-api", "get-blobs", "data-availability", "peerDAS"]}
/>

## Background

When a block is proposed, the CL can ask its local EL for the blobs via `engine_getBlobsV1/V2`. If the blob transactions were in the node's mempool, the EL returns them. If not (e.g., the transactions arrived late or were never broadcast publicly), the EL returns EMPTY.

From the [Fulu p2p-interface spec](https://github.com/ethereum/consensus-specs/blob/dev/specs/fulu/p2p-interface.md):

> Honest nodes SHOULD query `engine_getBlobsV2` as soon as they receive a valid `beacon_block` or `data_column_sidecar` from gossip. If ALL blobs matching `kzg_commitments` are retrieved, they should convert the response to data columns, and import the result.

This investigation looks at how often getBlobs returns EMPTY, whether blobs reach all nodes or just some, and whether nodes with EMPTY are slower to adopt the head.

```sql status_distribution
select * from xatu.private_blobs_status_distribution
```

```sql mev_distribution
select * from xatu.private_blobs_mev_distribution
```

```sql per_node_timing
select * from xatu.private_blobs_per_node_timing
```

```sql by_el_client
select * from xatu.private_blobs_by_el_client
```

```sql timing_distribution
select * from xatu.private_blobs_timing_distribution
```

```sql timing_by_blob_count
select * from xatu.private_blobs_timing_by_blob_count
```

```sql empty_rate_over_time
select * from xatu.private_blobs_empty_rate_over_time
```

## getBlobs Status Distribution

How often can nodes retrieve blobs from their local EL?

<SqlSource source="xatu" query="private_blobs_status_distribution" />

<BarChart
    data={status_distribution}
    x=status
    y=pct
    chartAreaHeight=250
    xAxisTitle="getBlobs Status"
    colorPalette={['#22c55e', '#f59e0b', '#ef4444']}
    echartsOptions={{
        grid: { left: 80, bottom: 50 },
        yAxis: { name: 'Percentage (%)', nameLocation: 'middle', nameGap: 45 }
    }}
/>

SUCCESS means the EL had all blobs in its txpool and returned them. EMPTY means the blob transactions hadn't reached that node's mempool yet.

### Empty rate over time

<SqlSource source="xatu" query="private_blobs_empty_rate_over_time" />

<LineChart
    data={empty_rate_over_time}
    x=hour
    y=empty_rate
    chartAreaHeight=300
    xAxisTitle="Time (UTC)"
    colorPalette={['#f59e0b']}
    xTickMarks=12
    echartsOptions={{
        grid: { left: 80, bottom: 100 },
        xAxis: { axisLabel: { rotate: 45, fontSize: 9, interval: 7 } },
        yAxis: { name: 'Empty Rate (%)', nameLocation: 'middle', nameGap: 45, min: 0, max: 15 }
    }}
/>

The empty rate varies from ~5% to ~14% over the course of the day. Peaks appear around 9-11 UTC and again around 21-23 UTC. This likely correlates with network activity patterns and timing game intensity.

## Mempool Propagation by Block Source

How well do blobs propagate through the mempool? We categorize slots by whether blobs reached nodes' EL txpools: "full propagation" means all nodes got SUCCESS, "partial propagation" means some SUCCESS and some EMPTY, and "truly private" means all nodes got EMPTY (blobs were never in the public mempool).

<SqlSource source="xatu" query="private_blobs_mev_distribution" />

<BarChart
    data={mev_distribution}
    x=mempool_status
    y=slots
    series=block_source
    type=grouped
    chartAreaHeight=300
    xAxisTitle="Mempool Propagation Status"
    colorPalette={['#8b5cf6', '#3b82f6']}
    echartsOptions={{
        grid: { left: 80, bottom: 100 },
        yAxis: { name: 'Slots', nameLocation: 'middle', nameGap: 55, type: 'log' }
    }}
/>

Truly private blobs are rare: only ~0.2% of MEV slots (about 12 slots/day) have blobs that never hit the public mempool. Partial propagation is the more common pattern, affecting ~71% of MEV slots and ~38% of local slots. MEV blocks show worse propagation overall (29% full vs 62% for local blocks), likely because timing games push blob transactions close to block proposal time, leaving less time for mempool gossip.

## Per-Node Head Timing Impact

Does getBlobs failure impact head adoption timing? To answer this, we compare nodes on the same slots where both SUCCESS and EMPTY outcomes occurred. This controls for slot-specific factors and isolates the getBlobs effect.

<SqlSource source="xatu" query="private_blobs_per_node_timing" />

<BarChart
    data={per_node_timing}
    x=getblobs_status
    y=median_head_time_ms
    chartAreaHeight=300
    xAxisTitle="getBlobs Status"
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        grid: { left: 80, bottom: 50 },
        yAxis: { name: 'Median Head Time (ms)', nameLocation: 'middle', nameGap: 55 }
    }}
/>

On average, nodes with EMPTY getBlobs are ~187ms slower (median 2405ms vs 2219ms) to adopt the head compared to nodes that got SUCCESS on the same slot, about an 8.4% increase. This is based on ~4,000 slots with mixed outcomes. The P2P gossip layer compensates (blobs eventually arrive via `blob_sidecar` or `data_column_sidecar` gossip), but there's measurable added latency.

But the overall number hides a lot of variance. Keep reading.

### Where does the timing penalty come from?

<SqlSource source="xatu" query="private_blobs_timing_distribution" />

<BarChart
    data={timing_distribution}
    x=timing_bucket
    y=observations
    series=getblobs_status
    type=grouped
    chartAreaHeight=300
    xAxisTitle="Head Adoption Time"
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        grid: { left: 80, bottom: 50 },
        yAxis: { name: 'Observations', nameLocation: 'middle', nameGap: 55 }
    }}
/>

SUCCESS nodes cluster heavily in the 1.5-2s bucket, while EMPTY nodes spread more evenly from 1.5-3s. The shift is visible but not dramatic.

### Does blob count matter?

<SqlSource source="xatu" query="private_blobs_timing_by_blob_count" />

<BarChart
    data={timing_by_blob_count}
    x=blob_count
    y=median_head_time_ms
    series=getblobs_status
    type=grouped
    chartAreaHeight=300
    xAxisTitle="Blob Count"
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        grid: { left: 80, bottom: 50 },
        yAxis: { name: 'Median Head Time (ms)', nameLocation: 'middle', nameGap: 55 }
    }}
/>

The penalty varies from 16ms to 432ms depending on blob count. 6 blobs is a weird outlier with almost no penalty (16ms) despite having the most observations. The rest of the data is noisy with no clear pattern.

## Impact by EL Client

Does the impact vary by execution layer client?

<SqlSource source="xatu" query="private_blobs_by_el_client" />

<BarChart
    data={by_el_client}
    x=el_client
    y=median_head_time_ms
    series=getblobs_status
    type=grouped
    chartAreaHeight=300
    xAxisTitle="EL Client"
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        grid: { left: 80, bottom: 50 },
        yAxis: { name: 'Median Head Time (ms)', nameLocation: 'middle', nameGap: 55 }
    }}
/>

The overall ~187ms penalty is almost entirely driven by **nethermind** (+310ms). Other clients show much smaller differences: geth (+57ms), erigon (+42ms), reth (+19ms). And some clients show EMPTY nodes being *faster*: besu (-243ms) and ethrex (-42ms).

So the "EMPTY nodes are slower" story doesn't hold across all clients. The per-client behavior is more complex and probably has more to do with the specific CL-EL pair being tested than the getBlobs outcome itself.
