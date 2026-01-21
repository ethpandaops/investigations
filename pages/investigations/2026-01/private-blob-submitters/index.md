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
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-21"
    author="samcm"
    tags={["blobs", "mempool", "l2", "data-availability"]}
/>

## Background

**Data range: January 17-20, 2026 (4 days)**

Blob transactions (EIP-4844) are typically broadcast to the public mempool before being included in blocks. However, some blobs appear in blocks without ever being seen in the mempool - these are "private blobs."

This investigation identifies which entities submit private blobs and how often.

```sql totals
select * from xatu.who_posts_private_blobs_totals
```

```sql summary
select * from xatu.who_posts_private_blobs_summary
```

```sql truly_private
select * from xatu.who_posts_private_blobs_truly_private
```

## Overall Blob Propagation

How many blobs reach the public mempool before being included in blocks?

<SqlSource source="xatu" query="who_posts_private_blobs_totals" />

<BarChart
    data={totals}
    x=status
    y=pct
    chartAreaHeight=250
    xAxisTitle="Propagation Status"
    colorPalette={['#ef4444', '#f59e0b', '#22c55e']}
    echartsOptions={{
        grid: { left: 80, bottom: 50 },
        yAxis: { name: 'Percentage (%)', nameLocation: 'middle', nameGap: 55 }
    }}
/>

- **Full Propagation**: All observing nodes had the blob in their mempool
- **Partial Propagation**: Some nodes had it, some didn't
- **Truly Private**: No node had it in their mempool - it appeared only in the block

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

## Who Submits Private Blobs?

<SqlSource source="xatu" query="who_posts_private_blobs_truly_private" />

<BarChart
    data={truly_private}
    x=submitter_name
    y=private_blobs
    swapXY=true
    chartAreaHeight=400
    sort=false
    colorPalette={['#ef4444']}
    echartsOptions={{
        grid: { left: 120, right: 40 },
        xAxis: { name: 'Truly Private Blobs', nameLocation: 'middle', nameGap: 35 }
    }}
/>

<DataTable data={truly_private} rows=15>
    <Column id="submitter_name" title="Submitter" />
    <Column id="address" title="Address" />
    <Column id="private_blobs" title="Private Blobs" fmt="num0" />
</DataTable>

**Base** leads with 50 truly private blobs over 4 days, followed by **World Chain** (15) and an unknown address (11). Most major L2s have a small number of truly private blobs.

## Propagation Quality by Submitter

Beyond truly private blobs, how well do each submitter's blobs propagate through the mempool?

<SqlSource source="xatu" query="who_posts_private_blobs_summary" />

<BarChart
    data={summary}
    x=submitter_name
    y=empty_rate
    swapXY=true
    chartAreaHeight=600
    colorPalette={['#f59e0b']}
    echartsOptions={{
        grid: { left: 120, right: 40 },
        xAxis: { name: 'Avg Empty Rate (%)', nameLocation: 'middle', nameGap: 35 }
    }}
/>

The "empty rate" is the percentage of nodes that don't have a blob in their mempool when the block arrives. Higher = worse propagation.

<DataTable data={summary} search=true rows=20>
    <Column id="submitter_name" title="Submitter" />
    <Column id="total_blobs" title="Total Blobs" fmt="num0" />
    <Column id="truly_private" title="Private" fmt="num0" />
    <Column id="partial" title="Partial" fmt="num0" />
    <Column id="full_propagation" title="Full" fmt="num0" />
    <Column id="empty_rate" title="Empty Rate %" fmt="num1" />
</DataTable>

## Key Findings

1. **Truly private blobs are rare** - only ~0.1% of all blobs never reach the public mempool
2. **Base and World Chain** have the most private blobs by absolute count, but this represents a tiny fraction of their volume
3. **Linea has the worst propagation** at 26% empty rate - their blobs often don't reach nodes before blocks arrive
4. **Partial propagation is common** - most blobs reach some nodes but not others, especially for high-volume L2s
5. **Unknown addresses** (not in our submitter mapping) account for some private blobs - worth investigating who these are
