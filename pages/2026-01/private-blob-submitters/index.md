---
title: Who Posts Private Blobs?
sidebar_position: 5
description: Identifying which L2s and entities submit blobs that never reach the public mempool
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
    description="Identifying which L2s and entities submit blobs that never reach the public mempool"
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

```sql truly_private
select * from xatu.who_posts_private_blobs_truly_private
```

<Section type="question">

## Question

Which entities submit blob transactions that bypass the public mempool, and how prevalent is this "private blob" behavior across L2s?

</Section>

<Section type="background">

## Background

Blob transactions (EIP-4844) are typically broadcast to the public mempool before being included in blocks. However, some blobs appear in blocks without ever being seen in the mempool - these are "private blobs."

**Propagation categories:**
- **Full Propagation** - All observing nodes had the blob in their mempool
- **Partial Propagation** - Some nodes had it, some did not
- **Truly Private** - No node had it in their mempool; it appeared only in the block

**Data range:** January 17-20, 2026 (4 days)

</Section>

<Section type="investigation">

## Investigation

### Overall Blob Propagation

How many blobs reach the public mempool before being included in blocks?

<SqlSource source="xatu" query="who_posts_private_blobs_totals" />

<BarChart
    data={totals}
    x=status
    y=pct
    title="Blob Propagation Status"
    chartAreaHeight=250
    colorPalette={['#ef4444', '#f59e0b', '#22c55e']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 80, top: 60, right: 30},
        xAxis: {name: 'Propagation Status', nameLocation: 'center', nameGap: 35},
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

<BigValue
    data={totals.filter(row => row.status === 'Truly Private')}
    value="blob_count"
    title="Truly Private Blobs"
    fmt="num0"
/>

<BigValue
    data={totals.filter(row => row.status === 'Truly Private')}
    value="pct"
    title="Private Rate (%)"
    fmt="num2"
/>

### Who Submits Private Blobs?

Which L2s and addresses are sending these truly private blobs?

<SqlSource source="xatu" query="who_posts_private_blobs_truly_private" />

<BarChart
    data={truly_private}
    x=submitter_name
    y=private_blobs
    swapXY=true
    title="Truly Private Blobs by Submitter"
    chartAreaHeight=400
    sort=false
    colorPalette={['#ef4444']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 120, top: 60, right: 40},
        xAxis: {name: 'Truly Private Blobs', nameLocation: 'center', nameGap: 35}
    }}
/>

<DataTable data={truly_private} rows=15>
    <Column id="submitter_name" title="Submitter" />
    <Column id="address" title="Address" />
    <Column id="private_blobs" title="Private Blobs" fmt="num0" />
</DataTable>

**Base** leads with 50 truly private blobs over 4 days, followed by **World Chain** (15) and an unknown address (11). Most major L2s have a small number of truly private blobs.

### Propagation Quality by Submitter

Beyond truly private blobs, how well do each submitter's blobs propagate through the mempool?

<SqlSource source="xatu" query="who_posts_private_blobs_summary" />

<BarChart
    data={summary}
    x=submitter_name
    y=empty_rate
    swapXY=true
    title="Mempool Empty Rate by Submitter"
    chartAreaHeight=600
    colorPalette={['#f59e0b']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 120, top: 60, right: 40},
        xAxis: {name: 'Avg Empty Rate (%)', nameLocation: 'center', nameGap: 35}
    }}
/>

The "empty rate" is the percentage of nodes that do not have a blob in their mempool when the block arrives. Higher = worse propagation.

<DataTable data={summary} search=true rows=20>
    <Column id="submitter_name" title="Submitter" />
    <Column id="total_blobs" title="Total Blobs" fmt="num0" />
    <Column id="truly_private" title="Private" fmt="num0" />
    <Column id="partial" title="Partial" fmt="num0" />
    <Column id="full_propagation" title="Full" fmt="num0" />
    <Column id="empty_rate" title="Empty Rate %" fmt="num1" />
</DataTable>

</Section>

<Section type="takeaways">

## Takeaways

- Truly private blobs are rare - only ~0.1% of all blobs never reach the public mempool
- Base and World Chain have the most private blobs by absolute count, but this represents a tiny fraction of their volume
- Linea has the worst propagation at 26% empty rate - their blobs often do not reach nodes before blocks arrive
- Partial propagation is common - most blobs reach some nodes but not others, especially for high-volume L2s
- Unknown addresses (not in our submitter mapping) account for some private blobs - worth investigating who these are

</Section>
