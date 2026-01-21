---
title: Timing Games
sidebar_position: 1
description: Which entities delay their blocks to extract more MEV? A week of timing data analyzed.
date: 2026-01-20
author: samcm
tags:
  - timing-games
  - mev
  - block-timing
  - validators
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-20"
    author="samcm"
    tags={["timing-games", "mev", "block-timing", "validators"]}
    description="Which entities delay their blocks to extract more MEV? A week of timing data analyzed."
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-13T00:00:00Z"
    endTime="2026-01-20T23:59:59Z"
/>

```sql entity_timing_analysis
select * from xatu_cbt.timing_games_entity_timing_analysis
```

```sql classification_summary
select * from xatu_cbt.timing_games_classification_summary
```

```sql score_distribution
select * from xatu_cbt.timing_games_score_distribution
order by case score_bucket
    when 'z < -2' then 1
    when '-2 ≤ z < -1' then 2
    when '-1 ≤ z < 0' then 3
    when '0 ≤ z < 1' then 4
    when '1 ≤ z < 2' then 5
    when '2 ≤ z < 3' then 6
    when 'z ≥ 3' then 7
    else 8
end
```

```sql top_suspects
select * from xatu_cbt.timing_games_top_suspects
```

```sql head_vote_impact
select * from xatu_cbt.timing_games_head_vote_impact
```

```sql scores_chart
select * from xatu_cbt.timing_games_scores_chart
```

```sql filtered_scores
select
    entity,
    block_count,
    arrival_seconds,
    z_score,
    classification,
    case
        when z_score < 0 then '#22c55e'
        when z_score >= 2 then '#ef4444'
        else '#eab308'
    end as bar_color,
    round(((z_score + 3) / 8.0) * 100, 1) as bar_width_pct,
    row_number() over (order by block_count desc) as rank
from ${scores_chart}
qualify rank <= ${inputs.top_n_filter.value}
order by z_score desc
```

<Section type="question">

## Question

Which entities delay their blocks to extract more MEV?

</Section>

<Section type="background">

## Background

Some validators delay their block proposals to squeeze out more MEV. This analysis looks at the past week to see who's doing it.

**How we score timing behavior**

We calculate a **timing game score** (z-score) for each entity based on their median block arrival time:

- **Conservative** (`z < 0`): Blocks arrive faster than average
- **Neutral** (`0 ≤ z ≤ 2`): Normal timing
- **Suspect** (`z > 2`): Blocks consistently arrive late, ~2 standard deviations above the mean

</Section>

<Section type="investigation">

## Investigation

### Classification Breakdown

<BigValue
    data={classification_summary.filter(row => row.classification === 'Conservative')}
    value="entity_count"
    title="Conservative"
    fmt="num0"
/>

<BigValue
    data={classification_summary.filter(row => row.classification === 'Neutral')}
    value="entity_count"
    title="Neutral"
    fmt="num0"
/>

<BigValue
    data={classification_summary.filter(row => row.classification === 'Suspect')}
    value="entity_count"
    title="Suspect"
    fmt="num0"
/>

<DataTable data={classification_summary}>
    <Column id="classification" title="Classification" />
    <Column id="entity_count" title="Entities" fmt="num0" />
    <Column id="total_blocks" title="Blocks" fmt="num0" />
    <Column id="avg_arrival_seconds" title="Avg arrival (s)" fmt="num3" />
</DataTable>

### Head Votes vs Blob Count

Late blocks with blobs get punished harder. The more blobs, the fewer head votes when you're late.

<SqlSource source="xatu_cbt" query="timing_games_head_vote_impact" />

<LineChart
    data={head_vote_impact}
    x="blob_count"
    y="head_vote_percentage"
    series="classification"
    title="Head Vote Percentage by Blob Count and Classification"
    chartAreaHeight=400
    markers=true
    markerSize=8
    lineWidth=3
    yMin=70
    colorPalette={['#22c55e', '#eab308', '#ef4444']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'Blob Count', nameLocation: 'center', nameGap: 35},
        yAxis: {min: 70, max: 100},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Head Vote (%)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

<DataTable data={head_vote_impact} rows=25>
    <Column id="classification" title="Classification" />
    <Column id="blob_count" title="Blobs" fmt="num0" />
    <Column id="head_vote_percentage" title="Head vote %" fmt="num2" />
    <Column id="total_attestations" title="Attestations" fmt="num0" />
</DataTable>

### Score Distribution

<SqlSource source="xatu_cbt" query="timing_games_score_distribution" />

<BarChart
    data={score_distribution}
    x="score_bucket"
    y="entity_count"
    title="Entity Count by Z-Score Bucket"
    sort=false
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'Z-Score Bucket', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Entity Count',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

### Timing Scores by Entity

<Dropdown
    name=top_n_filter
    title="Filter by block count"
    defaultValue="60"
>
    <DropdownOption value="20" valueLabel="Top 20" />
    <DropdownOption value="40" valueLabel="Top 40" />
    <DropdownOption value="60" valueLabel="Top 60" />
    <DropdownOption value="100" valueLabel="Top 100" />
    <DropdownOption value="999999" valueLabel="All" />
</Dropdown>

Sorted by score (most suspect at top). Only showing entities with enough blocks to matter.

<div style="margin: 20px 0; font-size: 12px;">
    <div style="display: flex; gap: 15px; margin-bottom: 10px; justify-content: center;">
        <span><span style="display: inline-block; width: 12px; height: 12px; background: #22c55e; border-radius: 2px;"></span> Conservative (z &lt; 0)</span>
        <span><span style="display: inline-block; width: 12px; height: 12px; background: #eab308; border-radius: 2px;"></span> Neutral (0 ≤ z &lt; 2)</span>
        <span><span style="display: inline-block; width: 12px; height: 12px; background: #ef4444; border-radius: 2px;"></span> Suspect (z ≥ 2)</span>
    </div>
    <div style="position: relative;">
        {#each filtered_scores as row}
        {#if row.z_score !== undefined && row.z_score !== null}
        <div style="display: flex; align-items: center; margin: 2px 0; height: 18px;">
            <div style="width: 130px; min-width: 130px; text-align: right; padding-right: 8px; font-size: 10px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="{row.entity}">{row.entity}</div>
            <div style="flex: 1; position: relative; height: 14px; background: #f3f4f6; border-radius: 2px;">
                <div style="position: absolute; left: 37.5%; height: 100%; width: 1px; background: #999;"></div>
                <div style="position: absolute; left: 62.5%; height: 100%; width: 2px; background: #dc2626; opacity: 0.5;"></div>
                {#if row.z_score >= 0}
                <div style="position: absolute; left: 37.5%; height: 100%; width: {Math.min((row.z_score / 8) * 100, 62.5)}%; background: {row.bar_color}; border-radius: 0 2px 2px 0;"></div>
                {:else}
                <div style="position: absolute; left: {37.5 + (row.z_score / 8) * 100}%; height: 100%; width: {(-row.z_score / 8) * 100}%; background: {row.bar_color}; border-radius: 2px 0 0 2px;"></div>
                {/if}
            </div>
            <div style="width: 50px; min-width: 50px; text-align: right; font-size: 10px; padding-left: 5px;">{row.z_score.toFixed(2)}</div>
        </div>
        {/if}
        {/each}
    </div>
    <div style="display: flex; margin-top: 5px; font-size: 10px; color: #666;">
        <div style="width: 130px; min-width: 130px;"></div>
        <div style="flex: 1; display: flex; justify-content: space-between; padding: 0 2px;">
            <span>-3</span>
            <span style="margin-left: 34.5%;">0</span>
            <span>5</span>
        </div>
        <div style="width: 50px; min-width: 50px;"></div>
    </div>
</div>

### Top Suspects (`z > 2`)

These entities consistently propose late. Min 10 blocks required.

<SqlSource source="xatu_cbt" query="timing_games_top_suspects" />

<DataTable data={top_suspects} rows=20>
    <Column id="entity" title="Entity" />
    <Column id="block_count" title="Blocks" fmt="num0" />
    <Column id="arrival_seconds" title="Median (s)" fmt="num3" />
    <Column id="z_score" title="Z-score" fmt="num2" />
</DataTable>

### All Entities

<SqlSource source="xatu_cbt" query="timing_games_entity_timing_analysis" />

<DataTable data={entity_timing_analysis} search=true rows=25>
    <Column id="entity" title="Entity" />
    <Column id="block_count" title="Blocks" fmt="num0" />
    <Column id="arrival_seconds" title="Median (s)" fmt="num3" />
    <Column id="z_score" title="Z-score" fmt="num2" />
    <Column id="classification" title="Classification" />
</DataTable>

</Section>

<Section type="takeaways">

## Takeaways

- Entities classified as "Suspect" (`z > 2`) consistently propose blocks later than average, likely to extract more MEV
- Late blocks with blobs are punished harder - the more blobs, the fewer head votes when proposing late
- The z-score distribution shows most entities cluster around neutral timing, with a tail of late proposers
- Conservative entities (`z < 0`) show that fast block propagation is possible - they're not playing timing games

</Section>
