---
title: Blob Mempool Propagation and Head Timing Impact
sidebar_position: 4
description: Analyzing how blob mempool propagation affects engine_getBlobsV2 success rates and per-node head timing
date: 2026-01-21T04:18:27Z
author: samcm
hidden: true
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
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-21T04:18:27Z"
    author="samcm"
    tags={["blobs", "mev", "engine-api", "get-blobs", "data-availability", "peerDAS"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-14T00:00:00Z"
    endTime="2026-01-21T23:59:59Z"
/>

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

<Section type="question">

## Question

How does blob mempool propagation affect `engine_getBlobsV2` success rates, and are nodes with failed getBlobs requests slower to adopt the head?

</Section>

<Section type="background">

## Background

When a block is proposed, the CL can ask its local EL for the blobs via `engine_getBlobsV1/V2`. If the blob transactions were in the node's mempool, the EL returns them. If not (e.g., the transactions arrived late or were never broadcast publicly), the EL returns EMPTY.

From the [Fulu p2p-interface spec](https://github.com/ethereum/consensus-specs/blob/dev/specs/fulu/p2p-interface.md):

> Honest nodes SHOULD query `engine_getBlobsV2` as soon as they receive a valid `beacon_block` or `data_column_sidecar` from gossip. If ALL blobs matching `kzg_commitments` are retrieved, they should convert the response to data columns, and import the result.

This investigation looks at how often getBlobs returns EMPTY, whether blobs reach all nodes or just some, and whether nodes with EMPTY are slower to adopt the head.

</Section>

<Section type="investigation">

## Investigation

### How often do nodes retrieve blobs locally?

How often can nodes retrieve blobs from their local EL?

<SqlSource source="xatu" query="private_blobs_status_distribution" />

<BarChart
    data={status_distribution}
    x=status
    y=pct
    title="getBlobs Status Distribution"
    chartAreaHeight=250
    colorPalette={['#22c55e', '#f59e0b', '#ef4444']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 50, top: 60, right: 30},
        xAxis: {name: 'getBlobs Status', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Percentage (%)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

SUCCESS means the EL had all blobs in its txpool and returned them. EMPTY means the blob transactions hadn't reached that node's mempool yet.

### How does the empty rate vary over time?

<SqlSource source="xatu" query="private_blobs_empty_rate_over_time" />

<LineChart
    data={empty_rate_over_time}
    x=hour
    y=empty_rate
    sort=false
    title="getBlobs Empty Rate Over Time"
    chartAreaHeight=300
    colorPalette={['#f59e0b']}
    xTickMarks=12
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 100, top: 60, right: 30},
        xAxis: {name: 'Time (UTC)', nameLocation: 'center', nameGap: 75, axisLabel: {rotate: 45, fontSize: 9, interval: 7}},
        yAxis: {min: 0, max: 15},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Empty Rate (%)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

The empty rate varies from ~5% to ~14% over the course of the day. Peaks appear around 9-11 UTC and again around 21-23 UTC. This likely correlates with network activity patterns and timing game intensity.

### How well do blobs propagate through the mempool?

We categorize slots by whether blobs reached nodes' EL txpools: "full propagation" means all nodes got SUCCESS, "partial propagation" means some SUCCESS and some EMPTY, and "truly private" means all nodes got EMPTY (blobs were never in the public mempool).

<SqlSource source="xatu" query="private_blobs_mev_distribution" />

<BarChart
    data={mev_distribution}
    x=mempool_status
    y=slots
    series=block_source
    type=grouped
    title="Mempool Propagation by Block Source"
    chartAreaHeight=300
    colorPalette={['#8b5cf6', '#3b82f6']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 100, top: 60, right: 30},
        xAxis: {name: 'Mempool Propagation Status', nameLocation: 'center', nameGap: 75},
        yAxis: {type: 'log'},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Slots',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

Truly private blobs are rare: only ~0.2% of MEV slots (about 12 slots/day) have blobs that never hit the public mempool. Partial propagation is the more common pattern, affecting ~71% of MEV slots and ~38% of local blocks. MEV blocks show worse propagation overall (29% full vs 62% for local blocks), likely because timing games push blob transactions close to block proposal time, leaving less time for mempool gossip.

### Does getBlobs failure impact head adoption timing?

To answer this, we compare nodes on the same slots where both SUCCESS and EMPTY outcomes occurred. This controls for slot-specific factors and isolates the getBlobs effect.

<SqlSource source="xatu" query="private_blobs_per_node_timing" />

<BarChart
    data={per_node_timing}
    x=getblobs_status
    y=median_head_time_ms
    title="Head Adoption Time by getBlobs Status"
    chartAreaHeight=300
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 50, top: 60, right: 30},
        xAxis: {name: 'getBlobs Status', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Median Head Time (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
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
    title="Head Adoption Time Distribution"
    chartAreaHeight=300
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 50, top: 60, right: 30},
        xAxis: {name: 'Head Adoption Time', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Observations',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

SUCCESS nodes cluster heavily in the 1.5-2s bucket, while EMPTY nodes spread more evenly from 1.5-3s. The shift is visible but not dramatic.

### Does blob count affect the timing penalty?

<SqlSource source="xatu" query="private_blobs_timing_by_blob_count" />

<BarChart
    data={timing_by_blob_count}
    x=blob_count
    y=median_head_time_ms
    series=getblobs_status
    type=grouped
    title="Head Adoption Time by Blob Count"
    chartAreaHeight=300
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 50, top: 60, right: 30},
        xAxis: {name: 'Blob Count', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Median Head Time (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

The penalty varies from 16ms to 432ms depending on blob count. 6 blobs is a weird outlier with almost no penalty (16ms) despite having the most observations. The rest of the data is noisy with no clear pattern.

### Does the impact vary by EL client?

<SqlSource source="xatu" query="private_blobs_by_el_client" />

<BarChart
    data={by_el_client}
    x=el_client
    y=median_head_time_ms
    series=getblobs_status
    type=grouped
    title="Head Adoption Time by EL Client"
    chartAreaHeight=300
    colorPalette={['#f59e0b', '#22c55e']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 50, top: 60, right: 30},
        xAxis: {name: 'EL Client', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Median Head Time (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

The overall ~187ms penalty is almost entirely driven by **nethermind** (+310ms). Other clients show much smaller differences: geth (+57ms), erigon (+42ms), reth (+19ms). And some clients show EMPTY nodes being *faster*: besu (-243ms) and ethrex (-42ms).

So the "EMPTY nodes are slower" story doesn't hold across all clients. The per-client behavior is more complex and probably has more to do with the specific CL-EL pair being tested than the getBlobs outcome itself.

</Section>

<Section type="takeaways">

## Takeaways

- **getBlobs succeeds most of the time**: The majority of requests return SUCCESS, meaning blob transactions typically reach node mempools before blocks are proposed
- **Truly private blobs are rare**: Only ~0.2% of MEV slots have blobs that never hit the public mempool; partial propagation is much more common (~71% of MEV slots)
- **MEV blocks have worse propagation**: Timing games push blob transactions close to proposal time, leaving less time for mempool gossip (29% full propagation vs 62% for local blocks)
- **EMPTY getBlobs adds ~187ms latency on average**: Nodes without blobs in their mempool are slower to adopt the head, but P2P gossip compensates
- **The timing penalty varies significantly by EL client**: Nethermind shows the largest penalty (+310ms), while besu and ethrex actually show faster head adoption with EMPTY results
- **No clear correlation with blob count**: The timing penalty doesn't increase predictably with more blobs

</Section>
