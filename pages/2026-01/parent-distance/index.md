---
title: Stale Parent Block Proposals
sidebar_position: 12
description: Analyzing how often Ethereum proposers build on non-direct parents, the resulting orphan rates, and which staking entities are most affected
date: 2026-01-27
author: samcm
tags:
  - block-proposals
  - parent-distance
  - staking-entities
  - network-health
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // Chart 1: Parent distance distribution with orphan rate overlay
    $: distributionConfig = (() => {
        if (!distribution || distribution.length === 0) return {};

        return {
            title: { text: 'Parent Distance Distribution (All Proposed Blocks)', left: 'center' },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const idx = params[0].dataIndex;
                    const d = distribution[idx];
                    let result = `Distance ${d.parent_distance}<br/>`;
                    result += `Total: ${Number(d.block_count).toLocaleString()}<br/>`;
                    result += `Canonical: ${Number(d.canonical).toLocaleString()}<br/>`;
                    result += `Orphaned: ${Number(d.orphaned).toLocaleString()}<br/>`;
                    result += `Orphan Rate: ${d.orphan_rate_pct}%<br/>`;
                    result += `Missed Slots Only: ${Number(d.missed_slots_only).toLocaleString()}`;
                    return result;
                }
            },
            legend: { data: ['Total Blocks', 'Orphan Rate'], right: 10, orient: 'vertical', top: 'center' },
            grid: { left: 80, right: 140, bottom: 60, top: 60 },
            xAxis: {
                type: 'category',
                data: distribution.map(d => String(d.parent_distance)),
                name: 'Parent Distance (slots)',
                nameLocation: 'center',
                nameGap: 35
            },
            yAxis: [
                {
                    type: 'log',
                    name: 'Block Count (log scale)',
                    nameLocation: 'center',
                    nameGap: 60,
                    nameRotate: 90
                },
                {
                    type: 'value',
                    name: 'Orphan Rate (%)',
                    nameLocation: 'center',
                    nameGap: 40,
                    nameRotate: 270,
                    min: 0,
                    max: 100,
                    axisLabel: { formatter: '{value}%' }
                }
            ],
            series: [
                {
                    name: 'Total Blocks',
                    type: 'bar',
                    data: distribution.map(d => d.block_count),
                    itemStyle: { color: '#2563eb' },
                    barMaxWidth: 60
                },
                {
                    name: 'Orphan Rate',
                    type: 'line',
                    yAxisIndex: 1,
                    data: distribution.map(d => d.orphan_rate_pct),
                    itemStyle: { color: '#dc2626' },
                    lineStyle: { color: '#dc2626', width: 2 },
                    symbol: 'circle',
                    symbolSize: 8
                }
            ]
        };
    })();

    // Chart 2: Daily truly stale parent rate
    $: dailyConfig = (() => {
        if (!daily || daily.length === 0) return {};

        const days = daily.map(d => d.day);
        const stalePct = daily.map(d => d.truly_stale_pct);
        const orphanedStale = daily.map(d => d.orphaned_truly_stale);

        return {
            title: { text: 'Daily Truly Stale Parent Rate', left: 'center' },
            tooltip: { trigger: 'axis' },
            legend: { data: ['Orphaned (Stale)', 'Truly Stale %'], right: 10, orient: 'vertical', top: 'center' },
            grid: { left: 80, right: 180, bottom: 80, top: 60 },
            xAxis: {
                type: 'category',
                data: days,
                axisLabel: { rotate: 45, fontSize: 10, interval: 6 },
                name: 'Date',
                nameLocation: 'center',
                nameGap: 60
            },
            yAxis: [
                {
                    type: 'value',
                    name: 'Block Count',
                    nameLocation: 'center',
                    nameGap: 50,
                    nameRotate: 90
                },
                {
                    type: 'value',
                    name: 'Truly Stale %',
                    nameLocation: 'center',
                    nameGap: 40,
                    nameRotate: 270,
                    min: 0,
                    axisLabel: { formatter: '{value}%' }
                }
            ],
            series: [
                {
                    name: 'Orphaned (Stale)',
                    type: 'bar',
                    data: orphanedStale,
                    itemStyle: { color: '#fca5a5' },
                    barMaxWidth: 8
                },
                {
                    name: 'Truly Stale %',
                    type: 'line',
                    yAxisIndex: 1,
                    data: stalePct,
                    itemStyle: { color: '#dc2626' },
                    lineStyle: { color: '#dc2626', width: 2 },
                    symbol: 'none',
                    smooth: true
                }
            ]
        };
    })();

    // Chart 3: Entity group summary (horizontal bar)
    $: entitySummaryConfig = (() => {
        if (!entity_summary || entity_summary.length === 0) return {};

        const sorted = [...entity_summary].sort((a, b) => a.truly_stale_pct - b.truly_stale_pct);
        const entities = sorted.map(d => d.entity_group);
        const pcts = sorted.map(d => d.truly_stale_pct);

        const colorMap = {
            'Solo Stakers': '#dc2626',
            'Rocket Pool': '#ea580c',
            'Lido CSM': '#16a34a',
            'Lido Professional': '#2563eb',
            'Unknown': '#6b7280',
            'Other': '#9333ea'
        };

        return {
            title: { text: 'Truly Stale Parent Rate by Entity Group', left: 'center' },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = sorted[d.dataIndex];
                    return `${d.name}<br/>Truly Stale Rate: ${d.value}%<br/>Truly Stale Blocks: ${row.truly_stale_blocks} (${row.orphaned_truly_stale} orphaned)<br/>Total Blocks: ${row.total_blocks.toLocaleString()}<br/>p50 Distance: ${row.p50_distance}<br/>p95 Distance: ${row.p95_distance}<br/>Max Distance: ${row.max_distance}`;
                }
            },
            grid: { left: 160, right: 40, bottom: 60, top: 60 },
            xAxis: {
                type: 'value',
                name: 'Truly Stale Parent Rate (%)',
                nameLocation: 'center',
                nameGap: 35,
                axisLabel: { formatter: '{value}%' }
            },
            yAxis: {
                type: 'category',
                data: entities,
                axisLabel: { fontSize: 12 }
            },
            series: [{
                type: 'bar',
                data: pcts.map((v, i) => ({
                    value: v,
                    itemStyle: { color: colorMap[entities[i]] || '#6b7280' }
                })),
                barMaxWidth: 40,
                label: {
                    show: true,
                    position: 'right',
                    formatter: '{c}%'
                }
            }]
        };
    })();

    // Chart 4: Entity distance distribution (selectable)
    let selectedEntity = 'Solo Stakers';
    $: entityGroups = distribution_by_entity
        ? [...new Set(distribution_by_entity.map(d => d.entity_group))].sort()
        : [];

    $: entityDistConfig = (() => {
        if (!distribution_by_entity || distribution_by_entity.length === 0) return {};

        const filtered = distribution_by_entity.filter(d => d.entity_group === selectedEntity);
        if (filtered.length === 0) return {};

        const colorMap = {
            'Solo Stakers': '#dc2626',
            'Rocket Pool': '#ea580c',
            'Lido CSM': '#16a34a',
            'Lido Professional': '#2563eb',
            'Unknown': '#6b7280',
            'Other': '#9333ea'
        };
        const color = colorMap[selectedEntity] || '#6b7280';

        return {
            title: { text: `Parent Distance Distribution: ${selectedEntity}`, left: 'center' },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const idx = params[0].dataIndex;
                    const d = filtered[idx];
                    let result = `Distance ${d.parent_distance}<br/>`;
                    result += `Total Blocks: ${Number(d.total_blocks).toLocaleString()}<br/>`;
                    result += `Truly Stale: ${Number(d.truly_stale_blocks).toLocaleString()}<br/>`;
                    result += `Orphaned: ${Number(d.orphaned_blocks).toLocaleString()}`;
                    return result;
                }
            },
            legend: { data: ['Total Blocks', 'Truly Stale'], right: 10, orient: 'vertical', top: 'center' },
            grid: { left: 80, right: 140, bottom: 60, top: 60 },
            xAxis: {
                type: 'category',
                data: filtered.map(d => String(d.parent_distance)),
                name: 'Parent Distance (slots)',
                nameLocation: 'center',
                nameGap: 35
            },
            yAxis: {
                type: 'log',
                name: 'Block Count (log scale)',
                nameLocation: 'center',
                nameGap: 60,
                nameRotate: 90
            },
            series: [
                {
                    name: 'Total Blocks',
                    type: 'bar',
                    data: filtered.map(d => d.total_blocks),
                    itemStyle: { color: color, opacity: 0.4 },
                    barMaxWidth: 40
                },
                {
                    name: 'Truly Stale',
                    type: 'bar',
                    data: filtered.map(d => d.truly_stale_blocks),
                    itemStyle: { color: color },
                    barMaxWidth: 40
                }
            ]
        };
    })();

    // Chart 5: Weekly trend by entity group (multi-line)
    $: weeklyEntityConfig = (() => {
        if (!weekly_by_entity || weekly_by_entity.length === 0) return {};

        const weeks = [...new Set(weekly_by_entity.map(d => d.week))];
        const groups = ['Solo Stakers', 'Rocket Pool', 'Lido CSM', 'Lido Professional'];

        const dataMap = {};
        weekly_by_entity.forEach(d => {
            if (!dataMap[d.entity_group]) dataMap[d.entity_group] = {};
            dataMap[d.entity_group][d.week] = d.truly_stale_pct;
        });

        const colorMap = {
            'Solo Stakers': '#dc2626',
            'Rocket Pool': '#ea580c',
            'Lido CSM': '#16a34a',
            'Lido Professional': '#2563eb'
        };

        const series = groups.map(name => ({
            name: name,
            type: 'line',
            data: weeks.map(w => dataMap[name]?.[w] ?? null),
            itemStyle: { color: colorMap[name] },
            lineStyle: { color: colorMap[name], width: 2 },
            symbol: 'circle',
            symbolSize: 6,
            connectNulls: true
        }));

        return {
            title: { text: 'Weekly Truly Stale Parent Rate by Entity Group', left: 'center' },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    let result = params[0].name + '<br/>';
                    params.forEach(p => {
                        if (p.value !== null && p.value !== undefined) {
                            result += `${p.marker} ${p.seriesName}: ${p.value}%<br/>`;
                        }
                    });
                    return result;
                }
            },
            legend: { data: groups, right: 10, orient: 'vertical', top: 'center' },
            grid: { left: 80, right: 170, bottom: 80, top: 60 },
            xAxis: {
                type: 'category',
                data: weeks,
                axisLabel: { rotate: 45, fontSize: 10 },
                name: 'Week',
                nameLocation: 'center',
                nameGap: 60
            },
            yAxis: {
                type: 'value',
                name: 'Truly Stale Parent Rate (%)',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90,
                min: 0,
                axisLabel: { formatter: '{value}%' }
            },
            series: series
        };
    })();
</script>

<PageMeta
    date="2026-01-27"
    author="samcm"
    tags={["block-proposals", "parent-distance", "staking-entities", "network-health"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-10-27T00:00:00Z"
    endTime="2026-01-27T00:00:00Z"
/>

```sql distribution
select * from xatu_cbt.parent_distance_distribution
```

```sql daily
select * from xatu_cbt.parent_distance_daily
```

```sql weekly_by_entity
select * from xatu_cbt.parent_distance_weekly_by_entity
```

```sql entity_summary
select * from xatu_cbt.parent_distance_entity_summary
```

```sql top_entities
select * from xatu_cbt.parent_distance_top_entities
```

```sql distribution_by_entity
select * from xatu_cbt.parent_distance_distribution_by_entity
```

<Section type="question">

## Question

How often do Ethereum proposers build on a genuinely stale parent (not just missed slots), and do solo stakers, Rocket Pool, or Lido CSM operators have disproportionately high stale parent rates?

</Section>

<Section type="background">

## Background

Every beacon block references a `parent_root` -- the block it builds on top of. In the normal case, a proposer builds on the immediately preceding canonical block (parent distance = 1). When a proposer's node is behind the chain tip, the proposed block will have a parent distance greater than 1.

A parent distance of 2 is usually benign: the previous slot was simply missed, and the proposer correctly built on the most recent canonical block. But when canonical blocks exist between the parent and the proposed block, the proposer genuinely missed them -- their node was out of sync. These "truly stale" blocks are almost guaranteed to be orphaned because fork choice will never prefer them over the canonical chain's accumulated attestation weight.

**Methodology**: For each block in `fct_block` (both canonical and orphaned), we self-join on `parent_root = block_root` to find the parent block's slot, then compute `slot - parent_slot` as the parent distance. To distinguish truly stale blocks from benign missed-slot cases, we check whether any canonical blocks exist between the parent slot and the proposed slot. If none exist, all intervening slots were missed and the proposer built correctly. If canonical blocks exist in between, the proposer was genuinely behind.

<img src="/stale-parent-blocks-explainer.jpg" alt="Truly Stale Parent — Slot 4 builds on Slot 1 instead of the canonical chain" style="max-width: 600px; width: 100%; display: block; margin: 0 auto;" />

*The block proposed in Slot 4 built on Slot 1 instead of Slot 3, giving it a parent distance of 3. Since canonical blocks exist in Slots 2 and 3, this is a truly stale parent reference.*

</Section>

<Section type="investigation">

## Investigation

### Parent Distance Distribution

<SqlSource source="xatu_cbt" query="parent_distance_distribution" />

<ECharts config={distributionConfig} height="400px" />

<DataTable data={distribution} rows=10>
    <Column id="parent_distance" title="Distance" />
    <Column id="block_count" title="Total" fmt="num0" />
    <Column id="canonical" title="Canonical" fmt="num0" />
    <Column id="orphaned" title="Orphaned" fmt="num0" />
    <Column id="orphan_rate_pct" title="Orphan Rate %" fmt="num2" />
    <Column id="missed_slots_only" title="Missed Slots Only" fmt="num0" />
    <Column id="pct" title="% of All" fmt="num4" />
</DataTable>

The relationship between parent distance and orphan rate is stark:

- **Distance 1**: 1.35% orphan rate (normal)
- **Distance 2**: 2.17% orphan rate -- but 98.4% of these are benign (the previous slot was simply missed)
- **Distance 3**: 34% orphaned
- **Distance 4**: 83% orphaned
- **Distance 5+**: **100% orphaned** -- no block with parent distance `>=` 5 has ever survived into the canonical chain in this 3-month window

### Is the Truly Stale Rate Changing?

<SqlSource source="xatu_cbt" query="parent_distance_daily" />

<ECharts config={dailyConfig} height="500px" />

The stacked bars show canonical truly stale blocks (blue) and orphaned truly stale blocks (red). The [Prysm Fusaka mainnet incident](https://prysm.offchainlabs.com/docs/misc/mainnet-postmortems/) on December 4, 2025 caused a clear spike in truly stale proposals, as Prysm nodes experienced resource exhaustion and fell behind the chain tip. Since mid-December, the rate has settled back to baseline.

### Entity Group Comparison

<SqlSource source="xatu_cbt" query="parent_distance_entity_summary" />

<ECharts config={entitySummaryConfig} height="400px" />

<DataTable data={entity_summary} rows=10>
    <Column id="entity_group" title="Entity Group" />
    <Column id="total_blocks" title="Total Blocks" fmt="num0" />
    <Column id="truly_stale_blocks" title="Truly Stale" fmt="num0" />
    <Column id="truly_stale_pct" title="Truly Stale %" fmt="num4" />
    <Column id="orphaned_truly_stale" title="Orphaned" fmt="num0" />
    <Column id="p50_distance" title="p50 Distance" fmt="num0" />
    <Column id="p95_distance" title="p95 Distance" fmt="num0" />
    <Column id="max_distance" title="Max Distance" fmt="num0" />
</DataTable>

With missed-slot cases excluded, **Solo Stakers** still have the highest truly stale parent rate. The p95 distance column reveals tail severity: Solo Stakers' stale blocks tend to be much further behind the chain tip than professional operators.

### Distance Distribution by Entity

<SqlSource source="xatu_cbt" query="parent_distance_distribution_by_entity" />

<div style="margin-bottom: 16px;">
    <label for="entity-select"><strong>Entity Group:</strong></label>
    <select id="entity-select" bind:value={selectedEntity} style="margin-left: 8px; padding: 4px 8px; border: 1px solid #d1d5db; border-radius: 4px;">
        {#each entityGroups as group}
            <option value={group}>{group}</option>
        {/each}
    </select>
</div>

<ECharts config={entityDistConfig} height="400px" />

The chart shows all blocks with parent distance > 1, broken down into total blocks (faded) and truly stale blocks (solid). The log scale reveals the tail -- select different entity groups to compare how far behind stale proposers typically are.

### Weekly Trend by Entity Group

<SqlSource source="xatu_cbt" query="parent_distance_weekly_by_entity" />

<ECharts config={weeklyEntityConfig} height="500px" />

The [Prysm Fusaka incident](https://prysm.offchainlabs.com/docs/misc/mainnet-postmortems/) (week of December 1, 2025) is clearly visible as a spike across all entity groups. Solo Stakers were disproportionately impacted -- likely because solo operators running Prysm were slower to apply the emergency fix compared to professional node operators who could respond faster.

### Top Individual Entities

<SqlSource source="xatu_cbt" query="parent_distance_top_entities" />

<DataTable data={top_entities} rows=15 search=true>
    <Column id="entity" title="Entity" />
    <Column id="total_blocks" title="Total Blocks" fmt="num0" />
    <Column id="truly_stale_blocks" title="Truly Stale" fmt="num0" />
    <Column id="truly_stale_pct" title="Truly Stale %" fmt="num4" />
    <Column id="orphaned_truly_stale" title="Orphaned" fmt="num0" />
    <Column id="p50_distance" title="p50 Dist" fmt="num1" />
    <Column id="p95_distance" title="p95 Dist" fmt="num1" />
</DataTable>

</Section>

<Section type="takeaways">

## Takeaways

- **Parent distance `>=` 5 means certain death**: 100% orphan rate. At distance 3, a third are orphaned. At distance 4, over 80%
- Most distance-2 blocks (98.4%) are benign -- the previous slot was simply missed. Only 1.6% represent a genuinely stale proposer
- **Solo Stakers have the highest truly stale parent rate**, with a fatter tail of deeply stale blocks (check the p95), suggesting real infrastructure/sync issues
- **Rocket Pool** and **Lido Professional** perform better, with Lido CSM lowest (small sample)
- The [Prysm Fusaka incident](https://prysm.offchainlabs.com/docs/misc/mainnet-postmortems/) (Dec 4, 2025) caused a clear spike across all groups. Solo Stakers were hit hardest and recovered slowest -- likely due to slower patching of the emergency fix
- The gap between solo and professional operators suggests that infrastructure quality (faster sync, better peering, redundant nodes, faster incident response) meaningfully reduces stale parent risk

</Section>
