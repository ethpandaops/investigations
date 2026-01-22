---
title: Does High Peer Count Help?
sidebar_position: 6
description: Investigating whether a node with 6k+ peers sees blocks faster than the rest of the network
date: 2026-01-22
author: samcm
tags:
  - block-propagation
  - peer-count
  - network-performance
  - xatu
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-22"
    author="samcm"
    tags={["block-propagation", "peer-count", "network-performance", "xatu"]}
    description="Investigating whether a node with 6k+ peers sees blocks faster than the rest of the network"
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-14T00:00:00Z"
    endTime="2026-01-21T23:59:59Z"
/>

```sql win_rate_daily
select * from xatu_cbt.high_peer_win_rate_daily
```

```sql win_rate_vs_nodes
select * from xatu_cbt.high_peer_win_rate_vs_nodes
```

```sql percentile_daily
select * from xatu_cbt.high_peer_percentile_daily
```

```sql timing_comparison
select * from xatu_cbt.high_peer_timing_comparison
```

```sql timing_scatter
select * from xatu_cbt.high_peer_timing_scatter
```

```sql timing_hourly
select * from xatu_cbt.high_peer_timing_hourly
```

```sql delta_hourly
select * from xatu_cbt.high_peer_delta_hourly
```

```sql percentile_hourly
select * from xatu_cbt.high_peer_percentile_hourly
```

<Section type="question">

## Question

Does having a massive peer count (6k+ peers) give a node a significant advantage in seeing blocks first?

</Section>

<Section type="background">

## Background

The Ethereum p2p network propagates blocks through a gossip protocol. In theory, having more peers should help a node receive blocks faster - more connections mean more chances to hear about a new block quickly.

We tested this hypothesis using **utility-mainnet-prysm-geth-tysm-003**, a Prysm/Geth node configured with ~6,000 peers (compared to the typical 50-100 peers for most nodes).

**Win rate** measures how often this node sees a block *first* among all nodes in the Xatu network (typically ~180 nodes). A random win rate would be about 0.56% (1/180 nodes).

**Percentile ranking** shows where this node falls in the distribution of block arrival times - e.g., 87th percentile means it sees blocks faster than 87% of the network.

</Section>

<Section type="investigation">

## Investigation

### When Competing for First

How often does our high-peer node see blocks first compared to the rest of the network?

<SqlSource source="xatu_cbt" query="high_peer_win_rate_daily" />

<LineChart
    data={win_rate_daily}
    x="day"
    y="win_rate_pct"
    sort=false
    title="Daily Win Rate for High-Peer Node"
    yFmt="num2"
    chartAreaHeight=400
    lineWidth=2
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {type: 'category', name: 'Date', nameLocation: 'center', nameGap: 35},
        yAxis: {min: 0, max: 0.7},
        series: [{
            markLine: {
                silent: true,
                symbol: 'none',
                label: {show: true, position: 'insideEndTop', formatter: 'Random chance (0.56%)'},
                lineStyle: {type: 'dashed', color: '#888'},
                data: [{yAxis: 0.56}]
            }
        }],
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Win Rate (%)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

With ~180 nodes competing, random chance would give a win rate of ~0.56%. Our high-peer node achieves about **0.33%** on average - actually *below* random chance. This suggests that while the node is consistently fast, a small group of exceptionally well-positioned nodes consistently beat it to first place.

### When Looking at Speed Ranking

A better measure than raw wins is *percentile ranking* - where does this node fall in the distribution of block arrival times?

<SqlSource source="xatu_cbt" query="high_peer_percentile_hourly" />

<LineChart
    data={percentile_hourly}
    x="hour"
    y={["P25", "Median", "Mean", "P75"]}
    sort=false
    title="Hourly Percentile Ranking (Higher = Faster)"
    yFmt="num1"
    chartAreaHeight=400
    yMax=100
    colorPalette={['#dc2626', '#2563eb', '#9333ea', '#16a34a']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 120},
        xAxis: {type: 'category', name: 'Time', nameLocation: 'center', nameGap: 35},
        yAxis: {min: 0, max: 100},
        legend: {show: true, right: 10, orient: 'vertical', top: 'center'},
        series: [
            {name: 'P25', lineStyle: {width: 2}},
            {name: 'Median', lineStyle: {width: 3}},
            {name: 'Mean', lineStyle: {width: 2, type: 'dashed'}},
            {name: 'P75', lineStyle: {width: 2}}
        ],
        graphic: [
            {
                type: 'text',
                left: 15,
                top: 'center',
                rotation: Math.PI / 2,
                style: {
                    text: 'Percentile (%)',
                    fontSize: 12,
                    fill: '#666'
                }
            }
        ]
    }}
/>

The high-peer node typically ranks in the **75th-95th percentile**, with a median around **85%**. However, there's notable variability - P25 can dip to ~50% while P75 reaches ~95%. This node is usually fast, but not consistently so.

### When Comparing Timing Over Time

How does our node's timing compare to the network median and fastest nodes over time?

<SqlSource source="xatu_cbt" query="high_peer_timing_hourly" />

<LineChart
    data={timing_hourly}
    x="hour"
    y={["Our Node", "Network Median", "Network Fastest"]}
    sort=false
    title="Hourly Block Arrival Time Comparison"
    yFmt="num0"
    chartAreaHeight=400
    colorPalette={['#2563eb', '#ea580c', '#16a34a']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 120},
        xAxis: {type: 'category', name: 'Time', nameLocation: 'center', nameGap: 35},
        yAxis: {min: 0},
        legend: {show: true, right: 10, orient: 'vertical', top: 'center'},
        series: [
            {name: 'Our Node', lineStyle: {width: 3}},
            {name: 'Network Median', lineStyle: {width: 2}},
            {name: 'Network Fastest', lineStyle: {width: 2}}
        ],
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Time After Slot Start (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

Our high-peer node consistently tracks between the network fastest and network median. The gap between our node and the median shows the advantage of having many peers.

### When Looking at Delta from Median

How much faster or slower is our node compared to the network median? Negative values mean we saw the block faster.

<SqlSource source="xatu_cbt" query="high_peer_delta_hourly" />

<AreaChart
    data={delta_hourly}
    x="hour"
    y="Delta from Median"
    sort=false
    title="Delta from Network Median (Negative = Faster)"
    yFmt="num0"
    chartAreaHeight=300
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {type: 'category', name: 'Time', nameLocation: 'center', nameGap: 35},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Delta (ms)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

The consistently negative delta shows our high-peer node sees blocks ~20-40ms faster than the network median on average.

</Section>

<Section type="takeaways">

## Takeaways

- A 6k+ peer count **does** provide a measurable speed advantage - seeing blocks ~30-40ms faster than the network median
- The node typically ranks around the **85th percentile** - usually faster than most of the network, but with notable variability
- However, the win rate is actually **below random chance** (~0.33% vs 0.56% expected) - a small group of exceptionally well-positioned nodes consistently beat our high-peer node to first place
- **Diminishing returns**: Having thousands of peers helps maintain consistently good performance, but doesn't overcome the advantage of optimal network positioning and infrastructure that some nodes have

</Section>
