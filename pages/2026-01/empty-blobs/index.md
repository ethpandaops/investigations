---
title: Who Posts Empty Blobs?
sidebar_position: 9
description: Identifying which entities submit blob transactions containing empty (zero-data) blobs on Ethereum mainnet
date: 2026-01-27T04:11:39Z
author: samcm
tags:
  - blobs
  - data-availability
  - aztec
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // Chart 1: Empty blobs by entity (bar chart)
    $: byEntityConfig = (() => {
        if (!by_entity || by_entity.length === 0) return {};

        const entities = by_entity.map(d => d.entity);
        const values = by_entity.map(d => d.empty_blobs);
        const colors = ['#2563eb', '#9333ea'];

        return {
            title: { text: 'Empty Blobs by Entity', left: 'center' },
            tooltip: { trigger: 'axis' },
            grid: { left: 80, right: 30, bottom: 60, top: 60 },
            xAxis: {
                type: 'category',
                data: entities,
                name: 'Entity',
                nameLocation: 'center',
                nameGap: 35
            },
            yAxis: {
                type: 'value',
                name: 'Empty Blobs',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90
            },
            series: [{
                type: 'bar',
                data: values.map((v, i) => ({
                    value: v,
                    itemStyle: { color: colors[i % colors.length] }
                })),
                barMaxWidth: 80
            }]
        };
    })();

    // Chart 2: Daily empty blobs (bar) with empty blob % (line on secondary axis)
    $: dailyConfig = (() => {
        if (!daily || daily.length === 0) return {};

        const days = daily.map(d => d.day);
        const emptyBlobs = daily.map(d => d['Empty Blobs']);
        const emptyPct = daily.map(d => d['Empty Blob %']);

        return {
            title: { text: 'Daily Empty Blobs', left: 'center' },
            tooltip: { trigger: 'axis' },
            legend: { data: ['Empty Blobs', 'Empty Blob %'], right: 10, orient: 'vertical', top: 'center' },
            grid: { left: 80, right: 120, bottom: 80, top: 60 },
            xAxis: {
                type: 'category',
                data: days,
                axisLabel: { rotate: 45, fontSize: 10 },
                name: 'Date',
                nameLocation: 'center',
                nameGap: 60
            },
            yAxis: [
                {
                    type: 'value',
                    name: 'Empty Blobs',
                    nameLocation: 'center',
                    nameGap: 50,
                    nameRotate: 90
                },
                {
                    type: 'value',
                    name: 'Empty %',
                    nameLocation: 'center',
                    nameGap: 40,
                    nameRotate: 270,
                    min: 0,
                    max: 10,
                    axisLabel: { formatter: '{value}%' }
                }
            ],
            series: [
                {
                    name: 'Empty Blobs',
                    type: 'bar',
                    data: emptyBlobs,
                    itemStyle: { color: '#2563eb' },
                    barMaxWidth: 60
                },
                {
                    name: 'Empty Blob %',
                    type: 'line',
                    yAxisIndex: 1,
                    data: emptyPct,
                    itemStyle: { color: '#dc2626' },
                    lineStyle: { color: '#dc2626', width: 2 }
                }
            ]
        };
    })();

    // Chart 3: Daily empty blobs by entity (stacked bar)
    $: dailyByEntityConfig = (() => {
        if (!daily_by_entity || daily_by_entity.length === 0) return {};

        const days = [...new Set(daily_by_entity.map(d => d.day))];
        const entities = [...new Set(daily_by_entity.map(d => d.entity))];

        const dataMap = {};
        daily_by_entity.forEach(d => {
            if (!dataMap[d.entity]) dataMap[d.entity] = {};
            dataMap[d.entity][d.day] = d.empty_blobs;
        });

        const colors = ['#2563eb', '#9333ea'];
        const series = entities.map((name, i) => ({
            name: name,
            type: 'bar',
            stack: 'total',
            data: days.map(d => dataMap[name]?.[d] || 0),
            itemStyle: { color: colors[i % colors.length] }
        }));

        return {
            title: { text: 'Daily Empty Blobs by Entity', left: 'center' },
            tooltip: { trigger: 'axis' },
            legend: { data: entities, right: 10, orient: 'vertical', top: 'center' },
            grid: { left: 80, right: 120, bottom: 80, top: 60 },
            xAxis: {
                type: 'category',
                data: days,
                axisLabel: { rotate: 45, fontSize: 10 },
                name: 'Date',
                nameLocation: 'center',
                nameGap: 60
            },
            yAxis: {
                type: 'value',
                name: 'Empty Blobs',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90
            },
            series: series
        };
    })();

</script>

<PageMeta
    date="2026-01-27T04:11:39Z"
    author="samcm"
    tags={["blobs", "data-availability", "aztec"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-16T00:00:00Z"
    endTime="2026-01-22T23:59:59Z"
/>

```sql by_entity
select * from xatu.empty_blobs_by_entity
```

```sql daily
select * from xatu.empty_blobs_daily
```

```sql daily_by_entity
select * from xatu.empty_blobs_daily_by_entity
```

```sql top_addresses
select * from xatu.empty_blobs_top_addresses
```

<Section type="question">

## Question

Who is posting empty blobs (blobs containing zero data) to Ethereum mainnet?

</Section>

<Section type="background">

## Background

An **empty blob** is a blob transaction where the blob data is entirely zeroes. These blobs have a distinctive KZG commitment: the BLS12-381 G1 point at infinity (`0xc00000...0000`), which produces the versioned hash `0x010657f37554c781402a22917dee2f75def7ab966d7b770905398eba3c444014`.

While blob transactions are designed to carry rollup data, nothing prevents submitting blobs with empty content. This raises questions: who is doing this, why, and does it matter?

</Section>

<Section type="investigation">

## Investigation

### Who Posts Empty Blobs

<SqlSource source="xatu" query="empty_blobs_by_entity" />

<ECharts config={byEntityConfig} height="400px" />

<DataTable data={by_entity} rows=10>
    <Column id="entity" title="Entity" />
    <Column id="total_txs" title="Transactions" fmt="num0" />
    <Column id="empty_blobs" title="Empty Blobs" fmt="num0" />
    <Column id="num_addresses" title="Addresses" fmt="num0" />
</DataTable>

**Aztec** is the dominant source of empty blobs, responsible for ~71% of all empty blob submissions across 135 distinct addresses. Each Aztec transaction contains exactly 1 empty blob, and 100% of Aztec's blob transactions are empty. The remaining ~29% come from unknown addresses.

### How Many Per Day

<SqlSource source="xatu" query="empty_blobs_daily" />

<ECharts config={dailyConfig} height="500px" />

<DataTable data={daily} rows=7>
    <Column id="day" title="Date" />
    <Column id="Total Blobs" title="Total Blobs" fmt="num0" />
    <Column id="Empty Blobs" title="Empty Blobs" fmt="num0" />
    <Column id="Empty Blob %" title="Empty %" fmt="num2" />
</DataTable>

Empty blobs represent a consistent 4-5% of all blobs on mainnet, with approximately 1,400-1,500 empty blobs posted daily.

### Daily Breakdown by Entity

<SqlSource source="xatu" query="empty_blobs_daily_by_entity" />

<ECharts config={dailyByEntityConfig} height="500px" />

Aztec consistently posts ~1,000 empty blobs per day, while unknown addresses contribute a steady ~400 per day.

### Top Addresses

<SqlSource source="xatu" query="empty_blobs_top_addresses" />

<DataTable data={top_addresses} rows=15 search=true>
    <Column id="address" title="Address" />
    <Column id="entity" title="Entity" />
    <Column id="total_txs" title="Transactions" fmt="num0" />
    <Column id="empty_blobs" title="Empty Blobs" fmt="num0" />
</DataTable>

Aztec uses a large number of rotating addresses to submit empty blobs. The top two addresses each posted ~1,300 empty blobs over the week. Several addresses in the top 15 are labeled as "Unknown" -- these may also be related to Aztec or other ZK rollup protocols.

</Section>

<Section type="takeaways">

## Takeaways

- **Aztec is the primary source of empty blobs**, posting ~1,000/day across 135 addresses, accounting for ~71% of all empty blob submissions
- Every Aztec blob transaction contains exactly **1 empty blob** (the BLS12-381 G1 point-at-infinity commitment) -- the reason is unknown
- Empty blobs represent **4-5% of all blobs** on mainnet, a non-trivial share of blob space

</Section>
