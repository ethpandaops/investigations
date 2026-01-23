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
    import { ECharts } from '@evidence-dev/core-components';

    // Transform nodes_over_time data for custom ECharts
    $: nodesOverTimeConfig = {
        title: {
            text: 'Distinct Nodes Observed per Hour',
            left: 'center'
        },
        tooltip: {
            trigger: 'axis'
        },
        grid: {
            left: 80,
            right: 30,
            bottom: 100,
            top: 60
        },
        xAxis: {
            type: 'category',
            data: nodes_over_time?.map(d => d.hour) || [],
            axisLabel: {
                interval: 23,
                rotate: 45,
                fontSize: 10
            },
            name: 'Time (UTC)',
            nameLocation: 'center',
            nameGap: 70
        },
        yAxis: {
            type: 'value',
            min: 10000,
            name: 'Distinct Nodes',
            nameLocation: 'center',
            nameGap: 50,
            nameRotate: 90
        },
        series: [{
            data: nodes_over_time?.map(d => d['Distinct Nodes']) || [],
            type: 'line',
            smooth: false,
            itemStyle: {
                color: '#2563eb'
            },
            lineStyle: {
                color: '#2563eb'
            }
        }],
        dataZoom: [{
            type: 'slider',
            start: 0,
            end: 100,
            bottom: 5,
            height: 30
        }]
    };

    // Transform nodes_by_client data for custom ECharts (multi-series)
    $: nodesByClientConfig = (() => {
        if (!nodes_by_client || nodes_by_client.length === 0) return {};

        // Get unique hours and clients
        const hours = [...new Set(nodes_by_client.map(d => d.hour))];
        const clients = [...new Set(nodes_by_client.map(d => d.client))];

        // Create a lookup map for quick access
        const dataMap = {};
        nodes_by_client.forEach(d => {
            if (!dataMap[d.client]) dataMap[d.client] = {};
            dataMap[d.client][d.hour] = d.nodes;
        });

        // Build series for each client
        const colorPalette = ['#2563eb', '#dc2626', '#16a34a', '#9333ea', '#ea580c', '#0891b2', '#4f46e5', '#84cc16', '#f97316', '#6366f1'];
        const series = clients.map((client, i) => ({
            name: client,
            type: 'line',
            data: hours.map(h => dataMap[client]?.[h] || 0),
            itemStyle: { color: colorPalette[i % colorPalette.length] },
            lineStyle: { color: colorPalette[i % colorPalette.length] }
        }));

        return {
            title: { text: 'Distinct Nodes by Client Type', left: 'center' },
            tooltip: { trigger: 'axis' },
            legend: {
                data: clients,
                right: 10,
                orient: 'vertical',
                top: 'center'
            },
            grid: { left: 80, right: 120, bottom: 100, top: 60 },
            xAxis: {
                type: 'category',
                data: hours,
                axisLabel: { interval: 23, rotate: 45, fontSize: 9 },
                name: 'Time (UTC)',
                nameLocation: 'center',
                nameGap: 70
            },
            yAxis: {
                type: 'value',
                name: 'Distinct Nodes',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90
            },
            series: series
        };
    })();
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

<ECharts config={nodesOverTimeConfig} height="500px" />

Over the week, we consistently observe around **10,000-12,000 distinct nodes** per hour via synthetic heartbeat.

### Nodes by Client Type

<SqlSource source="xatu" query="ipv4_nodes_by_client" />

<ECharts config={nodesByClientConfig} height="500px" />

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
