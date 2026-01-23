---
title: Who Posts Unavailable Blobs?
sidebar_position: 5
description: Identifying which L2s and entities submit blobs that aren't available to nodes when blocks arrive
date: 2026-01-21
author: samcm
tags:
  - blobs
  - mempool
  - l2
  - data-availability
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-21"
    author="samcm"
    tags={["blobs", "mempool", "l2", "data-availability"]}
    description="Identifying which L2s and entities submit blobs that aren't available to nodes when blocks arrive"
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-17T00:00:00Z"
    endTime="2026-01-20T23:59:59Z"
/>

```sql totals
select * from xatu.who_posts_private_blobs_totals
```

```sql summary
select * from xatu.who_posts_private_blobs_summary
```

```sql rate
select * from xatu.who_posts_private_blobs_rate
```

<Section type="question">

## Question

Which entities submit blob transactions that aren't available to nodes when blocks arrive, and how prevalent is this behavior across L2s?

</Section>

<Section type="background">

## Background

Blob transactions are typically broadcast to the public mempool before being included in blocks. This investigation examines which blobs were **not available** to our reference nodes when blocks arrived.

**Propagation categories:**
- **Full Propagation** - All observing nodes had the blob in their mempool when the block arrived
- **Partial Propagation** - Some nodes had it, some did not
- **Unavailable** - No node had the blob in their mempool when the block arrived

</Section>

<Section type="investigation">

## Investigation

**Important methodology note:** We monitor blob availability across **[7870 reference nodes](https://lab.ethpandaops.io/ethereum/execution/payloads)** via `engine_getBlobsV2`. When a block arrives, we check whether each node had the blob in its mempool. A blob being "unavailable" means our nodes didn't have it when the block was proposed. This doesn't necessarily mean the blob was never in the public mempool, only that it wasn't in the mempool on any of our nodes at the time the block was received for each node.

However, from a practical standpoint, if a blob isn't available to nodes when the block arrives **it's effectively the same as if the blob was never in the public mempool.** These nodes were not able to take advantage of the `engine_getBlobsV2` API.

### Overall Blob Availability

How many blobs were available to our reference nodes when blocks arrived?

<SqlSource source="xatu" query="who_posts_private_blobs_totals" />

<BarChart
    data={totals}
    x=status
    y=pct
    title="Blob Availability Status"
    chartAreaHeight=250
    colorPalette={['#ef4444', '#f59e0b', '#22c55e']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 80, top: 60, right: 30},
        xAxis: {name: 'Availability Status', nameLocation: 'center', nameGap: 35},
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

### Unavailable Rate (Top 15 by Volume)

Looking at the top 15 blob posters by volume, we can compare unavailable rates fairly.

<SqlSource source="xatu" query="who_posts_private_blobs_rate" />

<BarChart
    data={rate}
    x=submitter_name
    y=unavailable_rate
    yFmt=pct2
    swapXY=true
    title="Unavailable Rate by Submitter"
    chartAreaHeight=500
    sort=unavailable_rate
    colorPalette={['#8b5cf6']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 120, top: 60, right: 40},
        xAxis: {name: 'Unavailable Rate', nameLocation: 'center', nameGap: 35}
    }}
/>

<DataTable data={rate} rows=15 sort=unavailable_rate sortOrder=desc>
    <Column id="submitter_name" title="Submitter" />
    <Column id="total_blobs" title="Total Blobs" fmt="num0" />
    <Column id="unavailable_blobs" title="Unavailable" fmt="num0" />
    <Column id="unavailable_rate" title="Rate" fmt="pct2" />
</DataTable>

The table above shows unavailable rates for top blob posters. High-volume L2s like Base and World Chain have low unavailable rates when normalized, while several major L2s have 0% unavailable rates.

### Empty Rate by Submitter

Beyond completely unavailable blobs, what percentage of nodes are missing each submitter's blobs when blocks arrive?

<SqlSource source="xatu" query="who_posts_private_blobs_summary" />

<BarChart
    data={summary}
    x=submitter_name
    y=empty_rate
    swapXY=true
    title="Empty Rate by Submitter"
    chartAreaHeight=600
    colorPalette={['#f59e0b']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 120, top: 60, right: 40},
        xAxis: {name: 'Avg Empty Rate (%)', nameLocation: 'center', nameGap: 35}
    }}
/>

The "empty rate" is the average percentage of nodes that did not have a blob when the block arrived. Higher = worse propagation.

<DataTable data={summary} search=true rows=20>
    <Column id="submitter_name" title="Submitter" />
    <Column id="total_blobs" title="Total Blobs" fmt="num0" />
    <Column id="unavailable" title="Unavailable" fmt="num0" />
    <Column id="partial" title="Partial" fmt="num0" />
    <Column id="full_propagation" title="Full" fmt="num0" />
    <Column id="empty_rate" title="Empty Rate %" fmt="num1" />
</DataTable>

</Section>

<Section type="takeaways">

## Takeaways

- Completely unavailable blobs are rare: the vast majority of blobs are available to our [7870 reference nodes](https://lab.ethpandaops.io/ethereum/execution/payloads) when blocks arrive
- These blobs may have eventually reached the public mempool, but from our nodes' perspective they were effectively private since they weren't available in time for block verification
- **Absolute counts are misleading:** High-volume L2s may have more unavailable blobs in absolute terms, but very low rates when normalized by volume
- **Several major L2s have 0% unavailable rates**, showing that good mempool propagation is achievable
- Partial availability is common, with most blobs reaching some nodes but not others, especially for high-volume L2s


</Section>
