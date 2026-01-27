---
title: "Orphaned Slot 13505944"
sidebar_position: 11
description: A block built on a parent 19 slots behind the chain tip was orphaned with 0.46% head accuracy because fork choice could never prefer such a stale fork.
date: 2026-01-27T04:11:39Z
author: samcm
tags:
  - orphaned-block
  - block-timing
  - execution-payload
  - head-votes
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: headAccuracyConfig = {
        title: { text: 'Head Vote Accuracy by Slot', left: 'center' },
        tooltip: {
            trigger: 'axis',
            formatter: (params) => {
                const d = params[0];
                return `Slot ${d.name}<br/>Head Accuracy: ${d.value}%`;
            }
        },
        grid: { left: 80, right: 30, bottom: 60, top: 60 },
        xAxis: {
            type: 'category',
            data: head_accuracy?.map(d => String(d.slot)) || [],
            name: 'Slot',
            nameLocation: 'center',
            nameGap: 40
        },
        yAxis: {
            type: 'value',
            min: 0,
            max: 100,
            name: 'Head Vote Accuracy (%)',
            nameLocation: 'center',
            nameGap: 50,
            nameRotate: 90
        },
        series: [{
            data: head_accuracy?.map(d => d.head_accuracy_pct) || [],
            type: 'line',
            symbol: 'circle',
            symbolSize: 8,
            lineStyle: { color: '#2563eb', width: 3 },
            itemStyle: {
                color: (params) => {
                    const slot = head_accuracy?.[params.dataIndex]?.slot;
                    return slot == 13505944 ? '#dc2626' : '#2563eb';
                }
            }
        }]
    };

</script>

<PageMeta
    date="2026-01-27T04:11:39Z"
    author="samcm"
    tags={["orphaned-block", "block-timing", "execution-payload", "head-votes"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-20T07:49:11Z"
    endTime="2026-01-20T07:53:11Z"
/>

```sql head_accuracy
select * from xatu_cbt.stale_parent_head_accuracy
```

```sql head_voters
select * from xatu_cbt.stale_parent_head_voters
```


<Section type="question">

## Question

Why was the block at slot 13505944 orphaned despite containing a valid-looking payload with 909 transactions and 21 blobs?

</Section>

<Section type="background">

## Background

On January 20, 2026 at 07:49:11 UTC, validator 715575 (**blockscape_lido**) proposed a block at slot 13505944. The block achieved only **0.46% head votes**.

The [slot overview](https://lab.ethpandaops.io/ethereum/slots/13505944?tab=timeline) showed a late block (~2.9s) with a heavy payload (60M gas, 21 blobs), but even late heavy blocks typically achieve far higher head accuracy.

</Section>

<Section type="investigation">

## Investigation

### Head Vote Accuracy

Surrounding slots achieved 98-99% head accuracy. Slot 13505944 managed 0.46%.

<SqlSource source="xatu_cbt" query="stale_parent_head_accuracy" />

<ECharts config={headAccuracyConfig} height="400px" />

### Who Voted For It?

The only entity that voted for the block was all of the proposer's own operator's validators: **blockscape_lido**. This suggests that these validators were all running on the same node.

<SqlSource source="xatu_cbt" query="stale_parent_head_voters" />

<DataTable data={head_voters} />

### The Stale Parent

The proposed block's `parent_root` points to **slot 13505925** -- 19 slots behind the chain tip at slot 13505943.

| Field | Slot 13505944 (Proposed) | Expected (Canonical) |
|---|---|---|
| Beacon parent | Slot **13505925** | Slot 13505943 |
| Exec payload parent hash | `0xdbf1fc25...` (block 24274582) | `0xa113a54b...` (block 24274600) |
| Exec payload block number | **24274583** | 24274601 |

The proposer's node was stuck 19 slots (~3.8 minutes) behind the chain head. The block is valid on its own fork. However, the canonical chain has 19 slots of accumulated attestation weight that a single block cannot overcome.

```
Canonical chain at time of proposal:

  ... → 13505925 → 13505926 → ... → 13505943  (tip)
             ↑
             └── 13505944 built HERE (19 slots stale)
```

### Client Logs

A smple of logs from our nodes:

- **Reth**: `"Block added to fork chain"`
- **Nethermind**: `"Non consecutive block commit. Last: 24274600. New: 24274583"`
- **Lighthouse**: `block: "… empty"`

</Section>

<Section type="takeaways">

## Takeaways

- The proposer's node was stuck 19 slots behind the chain tip, building on slot 13505925 instead of 13505943
- The block is valid on its own fork, but fork choice could never prefer it over the canonical chain's 19 slots of accumulated weight
- **0.46% head accuracy** -- only 142 of 30,577 attestations voted for a block on a stale fork and all of them came from the proposer operator's own validators

</Section>
