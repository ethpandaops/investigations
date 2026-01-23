---
title: IPv4 Sharing on Mainnet
sidebar_position: 8
description: Analyzing how many peer_ids and clients share the same IPv4 address on mainnet
date: 2026-01-23
author: samcm
tags:
  - p2p
  - libp2p
  - network
  - synthetic-heartbeat
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-23"
    author="samcm"
    tags={["p2p", "libp2p", "network", "synthetic-heartbeat"]}
    description="Analyzing how many peer_ids and clients share the same IPv4 address on mainnet"
    networks={["Ethereum Mainnet"]}
    startTime="2026-01-16T00:00:00Z"
    endTime="2026-01-23T00:00:00Z"
/>

```sql peer_distribution
SELECT * FROM xatu.ipv4_peer_distribution
```

```sql nodes_over_time
SELECT * FROM xatu.ipv4_nodes_over_time
```

```sql nodes_by_client
SELECT * FROM xatu.ipv4_nodes_by_client
```

<Section type="question">

## Question

How many peer_ids and clients share the same IPv4 address on mainnet?

</Section>

<Section type="background">

## Background

On the Ethereum P2P network, each node has a unique **peer_id** derived from its cryptographic identity. Nodes running different **client implementations** (lighthouse, prysm, nimbus, etc.) can be identified via their agent string in libp2p.

Multiple peer_ids sharing an IP address can indicate:
- **Node operators** running multiple nodes behind NAT
- **Cloud providers** hosting many nodes on shared infrastructure
- **Sybil attacks** attempting to gain disproportionate influence

This analysis uses data from **synthetic heartbeat** messages - periodic pings that TYSM nodes send to peers, capturing their IP and client information. We measure **concurrent** peers using hourly snapshots rather than cumulative counts over time, which avoids conflating peer churn with actual density.

</Section>

<Section type="investigation">

## Investigation

### Distinct Nodes Over Time

<SqlSource source="xatu" query="ipv4_nodes_over_time" />

<LineChart
    data={nodes_over_time}
    x=hour
    y="Distinct Nodes"
    sort=false
    title="Distinct Nodes Observed per Hour"
    chartAreaHeight=300
    colorPalette={['#2563eb']}
    xAxisLabels=true
    xAxisTitle="Time (UTC)"
    xLabelWrap=true
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 80, top: 60, right: 30},
        xAxis: {axisLabel: {interval: 23, rotate: 45}},
        yAxis: {min: 10000},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Distinct Nodes',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

Over the week, we consistently observe around **10,000-12,000 distinct nodes** per hour via synthetic heartbeat.

### Nodes by Client Type

<SqlSource source="xatu" query="ipv4_nodes_by_client" />

<LineChart
    data={nodes_by_client}
    x=hour
    y=nodes
    series=client
    sort=false
    title="Distinct Nodes by Client Type"
    chartAreaHeight=350
    colorPalette={['#2563eb', '#dc2626', '#16a34a', '#9333ea', '#ea580c', '#0891b2', '#4f46e5', '#84cc16', '#f97316', '#6366f1']}
    xAxisLabels=true
    xAxisTitle="Time (UTC)"
    xLabelWrap=true
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 80, top: 60, right: 120},
        xAxis: {axisLabel: {interval: 23, rotate: 45}},
        legend: {show: true, right: 10, orient: 'vertical', top: 'center'},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Distinct Nodes',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

**Lighthouse** dominates with ~7,100 nodes, followed by **Prysm** (~3,900), **Nimbus** (~1,600), and **Teku** (~1,300).

### How are concurrent peer_ids distributed across IPs?

<SqlSource source="xatu" query="ipv4_peer_distribution" />

<BarChart
    data={peer_distribution}
    x="Peer IDs"
    y="IP Count"
    sort=false
    title="Distribution of Max Concurrent Peer IDs per IPv4"
    chartAreaHeight=350
    colorPalette={['#2563eb']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {left: 80, bottom: 50, top: 60, right: 30},
        xAxis: {name: 'Max Concurrent Peer IDs', nameLocation: 'center', nameGap: 35, type: 'category'},
        yAxis: {type: 'log'},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Number of IPs (log scale)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

The vast majority of IPs have only a single peer_id active at any given time. The max concurrent peers observed on any IP is around 10.

</Section>

<Section type="takeaways">

## Takeaways

- **Xatu is connected to a lot of nodes**: ~10,000 to 12,000 nodes in any given hour!
- **Most IPs have a single concurrent peer**: The vast majority of IPv4 addresses have only one peer_id active at any given hour
- **Low concurrent density**: The maximum concurrent peers on any IP is around 10

</Section>
