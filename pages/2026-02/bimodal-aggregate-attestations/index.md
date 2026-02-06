---
title: Bimodal Aggregate Attestations
sidebar_position: 1
description: Investigating the bimodal distribution in aggregate attestation propagation times on Ethereum mainnet
date: 2026-02-06T00:00:00Z
author: samcm
tags:
  - gossipsub
  - aggregate-attestations
  - prysm
  - propagation
  - libp2p
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // Chart 1: Bimodal histogram
    $: bimodalConfig = (() => {
        if (!bimodal || bimodal.length === 0 || bimodal[0].bin_ms == null) return {};
        return {
            title: { text: 'Aggregate Attestation Propagation Times (250ms bins)', left: 'center' },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    return `${(d.name / 1000).toFixed(1)}s: ${Number(d.value).toLocaleString()} messages`;
                }
            },
            grid: { left: 80, right: 30, bottom: 80, top: 60 },
            xAxis: {
                type: 'category',
                data: bimodal.map(d => Number(d.bin_ms)),
                axisLabel: {
                    interval: 7,
                    formatter: (v) => (Number(v) / 1000).toFixed(1) + 's',
                    fontSize: 10
                },
                name: 'Seconds from Slot Start',
                nameLocation: 'center',
                nameGap: 40
            },
            yAxis: { type: 'value' },
            series: [{
                type: 'bar',
                data: bimodal.map(d => Number(d.cnt)),
                itemStyle: { color: '#2563eb' },
                barWidth: '95%'
            }],
            graphic: [
                {
                    type: 'text',
                    left: 15,
                    top: 'center',
                    rotation: Math.PI / 2,
                    style: { text: 'Message Count', fontSize: 12, fill: '#666' }
                }
            ]
        };
    })();

    // Chart 2: Client tail percentage horizontal bar
    $: clientConfig = (() => {
        if (!client_breakdown || client_breakdown.length === 0 || client_breakdown[0].client == null) return {};
        const sorted = [...client_breakdown]
            .filter(d => d.client)
            .sort((a, b) => Number(a.tail_pct) - Number(b.tail_pct));
        const clientColor = (c) => {
            if (c === 'Prysm') return '#2563eb';
            if (c === 'Erigon') return '#16a34a';
            if (c === 'Unknown') return '#9ca3af';
            return '#64748b';
        };
        return {
            title: { text: 'Tail Percentage by Peer Client', left: 'center' },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    return `${d.name}: ${d.value}% of messages in tail`;
                }
            },
            grid: { left: 100, right: 80, bottom: 60, top: 60 },
            xAxis: {
                type: 'value',
                name: 'Messages in Tail (%)',
                nameLocation: 'center',
                nameGap: 40,
                max: 60
            },
            yAxis: {
                type: 'category',
                data: sorted.map(d => d.client)
            },
            series: [{
                type: 'bar',
                data: sorted.map(d => ({
                    value: Number(d.tail_pct),
                    itemStyle: { color: clientColor(d.client) }
                })),
                label: { show: true, position: 'right', formatter: '{c}%', fontSize: 11 }
            }]
        };
    })();

    // Chart 3: Scatter - tail P50 vs next-slot block arrival
    $: scatterConfig = (() => {
        if (!block_correlation || block_correlation.length === 0) return {};
        // Guard against Evidence lazy-loading proxies (keys exist but values are undefined)
        if (block_correlation[0].next_block_p50 == null) return {};

        const xs = block_correlation.map(d => Number(d.next_block_p50));
        const ys = block_correlation.map(d => Number(d.tail_p50));
        const data = xs.map((x, i) => [x, ys[i]]);
        const n = xs.length;
        const meanX = xs.reduce((a, b) => a + b, 0) / n;
        const meanY = ys.reduce((a, b) => a + b, 0) / n;
        const num = xs.reduce((s, x, i) => s + (x - meanX) * (ys[i] - meanY), 0);
        const den = xs.reduce((s, x) => s + (x - meanX) ** 2, 0);
        const slope = num / den;
        const intercept = meanY - slope * meanX;
        const ssRes = ys.reduce((s, y, i) => s + (y - (slope * xs[i] + intercept)) ** 2, 0);
        const ssTot = ys.reduce((s, y) => s + (y - meanY) ** 2, 0);
        const r = Math.sqrt(1 - ssRes / ssTot);
        const minX = Math.min(...xs);
        const maxX = Math.max(...xs);

        return {
            title: { text: `Tail Timing vs Next-Slot Block Arrival (r = ${r.toFixed(3)})`, left: 'center' },
            tooltip: {
                trigger: 'item',
                formatter: (p) => p.seriesType === 'scatter'
                    ? `Block: ${p.value[0]}ms, Tail P50: ${p.value[1]}ms`
                    : ''
            },
            grid: { left: 80, right: 30, bottom: 80, top: 60 },
            xAxis: {
                type: 'value',
                name: 'Block Arrival, Slot N+1 (ms from slot start)',
                nameLocation: 'center',
                nameGap: 45
            },
            yAxis: { type: 'value' },
            series: [
                {
                    type: 'scatter',
                    data: data,
                    symbolSize: 4,
                    itemStyle: { color: '#2563eb', opacity: 0.5 }
                },
                {
                    type: 'line',
                    data: [[minX, slope * minX + intercept], [maxX, slope * maxX + intercept]],
                    lineStyle: { color: '#dc2626', width: 2, type: 'dashed' },
                    symbol: 'none',
                    tooltip: { show: false }
                }
            ],
            graphic: [
                {
                    type: 'text',
                    left: 15,
                    top: 'center',
                    rotation: Math.PI / 2,
                    style: { text: 'Aggregate Tail P50, Slot N (ms)', fontSize: 12, fill: '#666' }
                }
            ]
        };
    })();

    // Chart 4: Rebroadcast stacked histogram (0-24s)
    $: gapConfig = (() => {
        if (!rebroadcast_gap || rebroadcast_gap.length === 0 || rebroadcast_gap[0].bin_s == null) return {};
        return {
            title: { text: 'Novel vs Rebroadcast Observations (1-hour sample)', left: 'center' },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const novel = params.find(p => p.seriesName === 'Novel');
                    const rebroadcast = params.find(p => p.seriesName === 'Rebroadcast');
                    const n = Number(novel?.value || 0);
                    const r = Number(rebroadcast?.value || 0);
                    const total = n + r;
                    const pct = total > 0 ? ((r / total) * 100).toFixed(1) : '0';
                    return `${params[0].name}s<br/>` +
                        `Novel: ${n.toLocaleString()}<br/>` +
                        `Rebroadcast: ${r.toLocaleString()} (${pct}%)`;
                }
            },
            legend: { data: ['Novel', 'Rebroadcast'], top: 30 },
            grid: { left: 80, right: 30, bottom: 80, top: 70 },
            xAxis: {
                type: 'category',
                data: rebroadcast_gap.map(d => Number(d.bin_s)),
                axisLabel: { fontSize: 11 },
                name: 'Seconds from Slot Start',
                nameLocation: 'center',
                nameGap: 40
            },
            yAxis: { type: 'value' },
            series: [
                {
                    name: 'Novel',
                    type: 'bar',
                    stack: 'total',
                    data: rebroadcast_gap.map(d => Number(d.novel_cnt)),
                    itemStyle: { color: '#2563eb' },
                    barWidth: '90%'
                },
                {
                    name: 'Rebroadcast',
                    type: 'bar',
                    stack: 'total',
                    data: rebroadcast_gap.map(d => Number(d.rebroadcast_cnt)),
                    itemStyle: { color: '#dc2626' },
                    barWidth: '90%'
                }
            ],
            graphic: [
                {
                    type: 'text',
                    left: 15,
                    top: 'center',
                    rotation: Math.PI / 2,
                    style: { text: 'Observation Count', fontSize: 12, fill: '#666' }
                }
            ]
        };
    })();

    // Chart 5: Peer behavior when caught behind vs had block (stacked horizontal bar)
    $: lagConfig = (() => {
        if (!lag_correlation || lag_correlation.length === 0 || lag_correlation[0].state == null) return {};
        const states = ['Caught behind', 'Had block'];
        const behaviors = ['Sent nothing', 'Only peak', 'Peak and tail', 'Only tail'];
        const behaviorColor = {
            'Sent nothing': '#94a3b8',
            'Only peak': '#2563eb',
            'Peak and tail': '#7c3aed',
            'Only tail': '#dc2626'
        };
        const dataMap = {};
        lag_correlation.forEach(d => {
            if (!dataMap[d.state]) dataMap[d.state] = {};
            dataMap[d.state][d.behavior] = { pct: Number(d.pct), cnt: Number(d.cnt) };
        });
        const totals = {};
        states.forEach(s => {
            totals[s] = behaviors.reduce((sum, b) => sum + (dataMap[s]?.[b]?.cnt || 0), 0);
        });
        return {
            title: { text: 'Prysm Peer Forwarding Behavior by Block State', left: 'center', textStyle: { fontSize: 14 } },
            tooltip: {
                trigger: 'axis',
                axisPointer: { type: 'shadow' },
                formatter: (params) => {
                    const state = params[0].name;
                    let s = `<b>${state}</b> (${totals[state]?.toLocaleString()} peer-slot pairs)<br/>`;
                    params.forEach(p => {
                        if (p.value > 0) s += `${p.marker} ${p.seriesName}: ${p.value}%<br/>`;
                    });
                    return s;
                }
            },
            legend: { data: behaviors, top: 35 },
            grid: { left: 130, right: 40, bottom: 40, top: 75 },
            xAxis: {
                type: 'value',
                max: 100,
                name: 'Peer-Slot Pairs (%)',
                nameLocation: 'center',
                nameGap: 25,
                axisLabel: { formatter: (v) => v + '%' }
            },
            yAxis: {
                type: 'category',
                data: states,
                axisLabel: { fontSize: 12 }
            },
            series: behaviors.map(b => ({
                name: b,
                type: 'bar',
                stack: 'total',
                data: states.map(s => dataMap[s]?.[b]?.pct || 0),
                itemStyle: { color: behaviorColor[b] },
                barWidth: '50%',
                label: {
                    show: true,
                    formatter: (p) => p.value >= 5 ? p.value + '%' : '',
                    fontSize: 11,
                    color: '#fff'
                }
            }))
        };
    })();

    // Chart 6: Per-peer tail rate box plot by client
    $: perPeerConfig = (() => {
        if (!per_peer || per_peer.length === 0 || per_peer[0].client == null) return {};
        const sorted = [...per_peer].filter(d => d.client);
        const clients = sorted.map(d => `${d.client} (${Number(d.peer_count).toLocaleString()} peers)`);
        const clientColor = {
            'Prysm': '#2563eb',
            'Lighthouse': '#f59e0b',
            'Teku': '#16a34a',
            'Erigon': '#dc2626',
            'Nimbus': '#9333ea',
            'Lodestar': '#ea580c',
            'Grandine': '#06b6d4'
        };
        return {
            title: { text: 'Per-Peer Tail Rate Distribution by Client', left: 'center' },
            tooltip: {
                trigger: 'item',
                formatter: (p) => {
                    if (p.componentType !== 'series') return '';
                    const d = sorted[p.dataIndex];
                    return `<b>${d.client}</b> (${Number(d.peer_count).toLocaleString()} peers)<br/>` +
                        `P95: ${d.p95}%<br/>` +
                        `Q3: ${d.q3}%<br/>` +
                        `Median: ${d.median}%<br/>` +
                        `Q1: ${d.q1}%<br/>` +
                        `P5: ${d.p5}%`;
                }
            },
            grid: { left: 160, right: 40, bottom: 60, top: 50 },
            xAxis: {
                type: 'value',
                name: 'Tail Rate per Peer (%)',
                nameLocation: 'center',
                nameGap: 35,
                min: 0,
                max: 100
            },
            yAxis: {
                type: 'category',
                data: clients
            },
            series: [
                {
                    name: 'P5-P95 range',
                    type: 'custom',
                    renderItem: (params, api) => {
                        const d = sorted[params.dataIndex];
                        const y = api.coord([0, params.dataIndex])[1];
                        const h = api.size([0, 1])[1] * 0.5;
                        const p5x = api.coord([Number(d.p5), 0])[0];
                        const q1x = api.coord([Number(d.q1), 0])[0];
                        const medx = api.coord([Number(d.median), 0])[0];
                        const q3x = api.coord([Number(d.q3), 0])[0];
                        const p95x = api.coord([Number(d.p95), 0])[0];
                        const color = clientColor[d.client] || '#64748b';
                        return {
                            type: 'group',
                            children: [
                                { type: 'line', shape: { x1: p5x, y1: y, x2: q1x, y2: y }, style: { stroke: color, lineWidth: 2 } },
                                { type: 'line', shape: { x1: q3x, y1: y, x2: p95x, y2: y }, style: { stroke: color, lineWidth: 2 } },
                                { type: 'line', shape: { x1: p5x, y1: y - h/3, x2: p5x, y2: y + h/3 }, style: { stroke: color, lineWidth: 2 } },
                                { type: 'line', shape: { x1: p95x, y1: y - h/3, x2: p95x, y2: y + h/3 }, style: { stroke: color, lineWidth: 2 } },
                                { type: 'rect', shape: { x: q1x, y: y - h/2, width: q3x - q1x, height: h }, style: { fill: color, opacity: 0.3, stroke: color, lineWidth: 2 } },
                                { type: 'line', shape: { x1: medx, y1: y - h/2, x2: medx, y2: y + h/2 }, style: { stroke: color, lineWidth: 3 } }
                            ]
                        };
                    },
                    data: sorted.map((d, i) => [Number(d.median), i]),
                    encode: { x: 0, y: 1 }
                }
            ]
        };
    })();
</script>

<PageMeta
    date="2026-02-06T00:00:00Z"
    author="samcm"
    tags={["gossipsub", "aggregate-attestations", "prysm", "propagation", "libp2p"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-02-05T00:00:00Z"
    endTime="2026-02-06T00:00:00Z"
/>

```sql bimodal
select * from xatu.bimodal_agg_att_histogram
```

```sql client_breakdown
select * from xatu.bimodal_agg_att_client_breakdown
```

```sql block_correlation
select * from xatu.bimodal_agg_att_block_correlation
```

```sql rebroadcast_gap
select * from xatu.bimodal_agg_att_rebroadcast_gap
```

```sql per_peer
select * from xatu.bimodal_agg_att_per_peer
```

```sql lag_correlation
select * from xatu.bimodal_agg_att_lag_correlation
```

<Section type="question">

## Question

Why do aggregate attestation propagation times on Ethereum mainnet show a bimodal distribution with a second peak 6-8 seconds after the first?

</Section>

<Section type="background">

## Background

**Aggregate attestations** are published by selected aggregators at 2/3 of each 12-second slot (~8s mark) on the `beacon_aggregate_and_proof` gossipsub topic. Under normal conditions, they should arrive as a single cluster around the 8s mark.

Instead, we observe two distinct peaks: a main peak at ~8s and a second peak at ~14-16s. The second peak comprises roughly **28% of all observed messages** and is remarkably consistent across time windows (10 minutes to 24 hours).

This investigation traces the source of the second peak through gossipsub peer data and cross-references it with consensus client source code.

</Section>

<Section type="investigation">

## Investigation

### When Observing Propagation

The histogram below shows aggregate attestation arrival times in 250ms bins.

<SqlSource source="xatu" query="bimodal_agg_att_histogram" />

<ECharts config={bimodalConfig} height="450px" />

The bimodal shape is unmistakable. The main peak centers around 8-9s (normal gossip propagation), while a second peak forms around 14-16s - consistently about 12 seconds offset from slot start, aligning with the *next* slot boundary.

### When Confirming Rebroadcasts

To determine whether tail messages are novel aggregates arriving late or rebroadcasts of already-seen messages, we classified each observation by its gossipsub `message_id`. An observation is "rebroadcast" if the same `message_id` was first seen in an earlier 1-second bin - meaning the message had already propagated through the network before being re-published.

<SqlSource source="xatu" query="bimodal_agg_att_rebroadcast_gap" />

<ECharts config={gapConfig} height="450px" />

The second peak (14-16s) is almost entirely red - these are rebroadcasts of messages that already arrived during the main peak at 8-9s. Overall, **95.2% of tail observations** share a `message_id` with an earlier peak observation. Only **1.6% of unique `message_id` values** appear exclusively in the tail.

### When Identifying the Source

By joining peer IDs with heartbeat data, we can identify which client each message was forwarded by. The chart below shows what percentage of each client's forwarded messages fall in the tail.

<SqlSource source="xatu" query="bimodal_agg_att_client_breakdown" />

<ECharts config={clientConfig} height="400px" />

**Prysm accounts for ~51% tail** - nearly half of all messages it relays arrive late. In contrast, Teku shows `<` 1% tail and Lighthouse ~1%. This points to a Prysm-specific mechanism. Note that Erigon also shows an elevated tail (~19%), though we observe far fewer Erigon peers than Prysm peers so the comparison should be interpreted with caution.

### When Examining Per-Peer Variance

The per-client averages above mask enormous variance across individual peers. The chart below shows the distribution of tail rates for individual peers, grouped by client. Each peer's tail rate is the percentage of their forwarded aggregates that land in the tail window.

<SqlSource source="xatu" query="bimodal_agg_att_per_peer" />

<ECharts config={perPeerConfig} height="450px" />

Lighthouse and Teku peers cluster tightly near 0% (median 0.0%, P95 under 4%). Prysm peers are spread across the entire range (median 30%, IQR 10-54%) - some peers show almost no tail while others push above 80%. This suggests the rebroadcast behavior depends heavily on individual node state, likely how quickly each node processes blocks relative to when aggregates arrive.

### When Tracing the Trigger

After staring at the histogram long enough, the second peak at 14-16s starts to look suspiciously like the shape of block arrivals for the *next* slot (~12s from slot start). If that's not pareidolia, it would suggest a mechanism where block N+1's arrival triggers the delayed processing. One possibility: if a node is missing block N when aggregates arrive at 8s, it may not fetch block N until block N+1 arrives and reveals the missing parent - at which point the node requests block N via req/resp and processes the queued aggregates. To test this, for each slot N we plot the aggregate tail P50 against the block arrival time at slot N+1.

<SqlSource source="xatu" query="bimodal_agg_att_block_correlation" />

<ECharts config={scatterConfig} height="500px" />

The correlation is strong (r = 0.91). Tail timing for slot N's aggregates tracks closely with when slot N+1's block arrives on the network, consistent with a mechanism triggered by block processing.

### When Catching Peers Behind

The `libp2p_handle_status` table records periodic status exchanges with each peer (~every 4 seconds), including their reported `head_slot`. For each Prysm peer, we checked outbound status exchanges during seconds 5-8 of each slot - right around the aggregation deadline. If a peer's `response_head_slot` was less than our `request_head_slot`, we classified them as "caught behind" for that slot. We then checked what aggregate attestations that peer forwarded to us for that same slot.

<SqlSource source="xatu" query="bimodal_agg_att_lag_correlation" />

<ECharts config={lagConfig} height="300px" />

Peers caught behind are almost completely silent: **96.5%** sent us nothing at all, compared to 58.5% for peers that had the block. Prysm nodes that haven't processed the referenced block suppress gossip forwarding entirely - they don't forward the aggregate to any of their mesh peers.

At first glance, the low tail rate from behind peers (0.7%) might seem to contradict the idea that slow block processing causes the tail. If these peers are the source of the problem, why aren't *they* the ones sending us tail messages? Is there a race condition at play - and if so, how does the re-broadcast actually propagate through the network?

### Analysis

#### Prysm: Possible Pending Queue Re-broadcast

Prysm's source code contains a mechanism that may explain the tail. When a Prysm node receives an aggregate but hasn't processed the referenced block yet, it saves the aggregate to a pending queue and returns `ValidationIgnore` (suppressing gossip forwarding). From [`validate_aggregate_proof.go`](https://github.com/prysmaticlabs/prysm/blob/862fb2eb4a13ddd6db636b5d53de3d0af7b83866/beacon-chain/sync/validate_aggregate_proof.go#L245-L256):

```go
func (s *Service) validateBlockInAttestation(ctx context.Context, satt ethpb.SignedAggregateAttAndProof) bool {
    blockRoot := bytesutil.ToBytes32(satt.AggregateAttestationAndProof().AggregateVal().GetData().BeaconBlockRoot)
    if !s.hasBlockAndState(ctx, blockRoot) {
        s.savePendingAggregate(satt)
        return false
    }
    return true
}
```

When the missing block eventually arrives, [`processPendingAttsForBlock()`](https://github.com/prysmaticlabs/prysm/blob/862fb2eb4a13ddd6db636b5d53de3d0af7b83866/beacon-chain/sync/subscriber_beacon_blocks.go#L60-L82) flushes the queue. This is called immediately after block import in `beaconBlockSubscriber`. Notably, the [pending blocks queue](https://github.com/prysmaticlabs/prysm/blob/862fb2eb4a13ddd6db636b5d53de3d0af7b83866/beacon-chain/sync/pending_blocks_queue.go#L134-L142) also performs parent-chain sync: when block N+1 arrives but parent N is missing, Prysm sends a `BeaconBlocksByRoot` req/resp request to fetch block N. This may explain the strong r=0.91 correlation with block N+1's arrival - the next block's arrival triggers the fetch of the missing parent, which then flushes the pending attestations.

For each pending aggregate, [`processAggregate()`](https://github.com/prysmaticlabs/prysm/blob/862fb2eb4a13ddd6db636b5d53de3d0af7b83866/beacon-chain/sync/pending_attestations_queue.go#L352-L375) re-publishes it via gossipsub:

```go
func (s *Service) processAggregate(ctx context.Context, aggregate ethpb.SignedAggregateAttAndProof) error {
    res, err := s.validateAggregatedAtt(ctx, aggregate)
    if err != nil {
        return errors.Wrap(err, "validate aggregated att")
    }
    if res != pubsub.ValidationAccept || !s.validateBlockInAttestation(ctx, aggregate) {
        return errors.New("Pending aggregated attestation failed validation")
    }
    att := aggregate.AggregateAttestationAndProof().AggregateVal()
    if err := s.saveAttestation(att); err != nil {
        return errors.Wrap(err, "save attestation")
    }
    _ = s.setAggregatorIndexEpochSeen(att.GetData().Target.Epoch,
        aggregate.AggregateAttestationAndProof().GetAggregatorIndex())

    if err := s.cfg.p2p.Broadcast(ctx, aggregate); err != nil {
        log.WithError(err).Debug("Could not broadcast aggregated attestation")
    }
    return nil
}
```

This `Broadcast()` call is a full gossipsub re-publish. If this code path is responsible for the tail, the propagation may work as follows: because the original aggregate was handled with `ValidationIgnore`, it would not be added to the gossipsub seen cache on the behind node. So the re-broadcast could propagate through other behind Prysm nodes that also returned `ValidationIgnore` and lack the `message_id` in their seen cache - while peers that already accepted the original would correctly deduplicate and ignore it.

Per-peer variance is massive (IQR 10-54% across individual Prysm nodes), suggesting node-specific state (block processing latency, mesh topology) strongly modulates the effect. If this is the mechanism, it would function as a race condition:

![Prysm race condition diagram](/images/prysm-race-condition.jpg)

**Fast nodes** that have already processed the referenced block return `ValidationAccept` immediately - the aggregate is forwarded during the main peak at 8-9s. **Slow nodes** that haven't processed the block yet queue the aggregate and return `ValidationIgnore`. When the block finally arrives, the pending queue is flushed and `Broadcast()` re-publishes the aggregate - producing the second peak at 14-16s.

#### Erigon: Proposer-Only Forwarding

Since the Fulu fork (activated Dec 3, 2025), Erigon's Caplin consensus layer only processes aggregates on nodes with upcoming proposer duties. In [`aggregate_and_proof_service.go`](https://github.com/erigontech/erigon/blob/627b07ddbb6fa04c73e1a3e9a0985d32026704c4/cl/phase1/network/services/aggregate_and_proof_service.go#L129-L135), the `isLocalValidatorProposer` check gates all aggregate processing:

```go
func (a *aggregateAndProofServiceImpl) isLocalValidatorProposer(
    headState *state.CachingBeaconState, currentEpoch uint64, localValidators []uint64,
) bool {
    if headState.Version() < clparams.FuluVersion {
        return true // pre-Fulu: process everything
    }
    // Fulu+: only if a local validator is proposer in current or next epoch
    // ...
```

When no local validator is a proposer, [`aggregateVerificationData` stays nil](https://github.com/erigontech/erigon/blob/627b07ddbb6fa04c73e1a3e9a0985d32026704c4/cl/phase1/network/services/aggregate_and_proof_service.go#L298-L315) and the aggregate is dropped:

```go
    if localValidatorIsProposer || aggregateAndProof.ImmediateProcess {
        aggregateVerificationData, err = GetSignaturesOnAggregate(
            headState, aggregateAndProof.SignedAggregateAndProof, attestingIndices)
        // ...
    }
    // ...
    if aggregateVerificationData == nil {
        return ErrIgnore // → ValidationIgnore, message NOT forwarded
    }
```

This means most Erigon nodes on post-Fulu mainnet are **dead-ends** for aggregate attestations - they return `ValidationIgnore` for every aggregate, suppressing gossip forwarding.

Erigon also performs a [block-seen check](https://github.com/erigontech/erigon/blob/627b07ddbb6fa04c73e1a3e9a0985d32026704c4/cl/phase1/network/services/aggregate_and_proof_service.go#L239-L242) similar to Prysm's, but without a pending queue:

```go
    if _, ok := a.forkchoiceStore.GetHeader(aggregateData.BeaconBlockRoot); !ok {
        return fmt.Errorf("%w: block not seen: %v", ErrIgnore, aggregateData.BeaconBlockRoot)
    }
```

Unlike Prysm, there is no `savePendingAggregate()` and no re-broadcast. A [pending queue exists](https://github.com/erigontech/erigon/blob/627b07ddbb6fa04c73e1a3e9a0985d32026704c4/cl/phase1/network/services/aggregate_and_proof_service.go#L187-L191) but the call is commented out:

```go
    if aggregateData.Slot > a.syncedDataManager.HeadSlot() {
        //a.scheduleAggregateForLaterProcessing(aggregateAndProof)
        return fmt.Errorf("%w: aggregate is for a future slot", ErrIgnore)
    }
```

**Why we still see ~19% tail from Erigon peers:** the Erigon peers in our data may have returned `ValidationAccept` - i.e. nodes with active proposer duties that accept and forward aggregates. Since non-proposing Erigon nodes return `ValidationIgnore` (like behind Prysm nodes), they also don't add the `message_id` to their gossipsub seen cache. When Prysm re-broadcasts arrive, Erigon proposer-nodes that are meshed with behind peers may receive these re-broadcasts and forward them - producing the ~19% tail rate.

</Section>

<Section type="takeaways">

## Takeaways

- **~28% of aggregate attestation observations are rebroadcasts**, not late-arriving novel messages. 95.2% of tail observations share a `message_id` with a peak observation
- **Prysm's pending attestation queue may be the cause.** When a Prysm node hasn't processed the referenced block, it queues the aggregate and returns `ValidationIgnore`. When the block arrives, it re-publishes via `Broadcast()`. Tail timing correlates with block arrival at **r = 0.91**
- **`ValidationIgnore` may create a gossipsub seen-cache hole** that allows the re-broadcast to cascade through other behind Prysm nodes. Peers that already accepted the original deduplicate and ignore it - which may explain why Teku (`<` 1%) and Lighthouse (~1%) show almost no tail
- **Per-peer variance is high** (Prysm IQR 10-54%), driven by how quickly each node processes blocks relative to aggregate arrival

</Section>
