---
title: Glamsterdam SSE event support by client on devnet-6
sidebar_position: 1
description: Checks which consensus clients emit each of the six new Glamsterdam beacon API SSE events on glamsterdam-devnet-6, using per-client xatu-sentry observations.
date: 2026-07-10T06:00:00Z
author: samcm
tags:
  - glamsterdam
  - gloas
  - epbs
  - xatu
  - devnets
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';

    const clients = ['grandine', 'lighthouse', 'lodestar', 'nimbus', 'prysm', 'teku'];

    // Per-client event counts from sources/xatu/glam_sse_client_matrix.sql,
    // pinned for the fixed window 2026-06-25 to 2026-07-09 23:59:59 UTC.
    const sseCounts = {
        'execution_payload':           { grandine: 45055,  lighthouse: 40867,    lodestar: 33695,  nimbus: 39180,  prysm: 42626,    teku: 38394 },
        'execution_payload_available': { grandine: 282769, lighthouse: 289908,   lodestar: 215912, nimbus: 276633, prysm: 312075,   teku: 264958 },
        'execution_payload_bid':       { grandine: 273098, lighthouse: 296013,   lodestar: 237701, nimbus: 0,      prysm: 290668,   teku: 190681 },
        'execution_payload_gossip':    { grandine: 44927,  lighthouse: 40882,    lodestar: 33543,  nimbus: 38937,  prysm: 37364,    teku: 38061 },
        'payload_attestation':         { grandine: 0,      lighthouse: 49478176, lodestar: 0,      nimbus: 0,      prysm: 53073872, teku: 45038702 },
        'proposer_preferences':        { grandine: 0,      lighthouse: 299619,   lodestar: 221362, nimbus: 0,      prysm: 320261,   teku: 264946 }
    };
    const matrix = Object.entries(sseCounts).map(([event, counts]) => ({
        event,
        cells: clients.map(c => counts[c])
    }));

    // Sentry coverage from sources/xatu/glam_client_coverage.sql, same window.
    // Versions are those observed on 2026-07-08/09.
    const coverage = [
        { client: 'grandine',   nodes: 14, first: '2026-07-02', versions: '2.0.4-da4baf15' },
        { client: 'lighthouse', nodes: 16, first: '2026-06-25', versions: 'v8.2.0-0daf331' },
        { client: 'lodestar',   nodes: 16, first: '2026-06-25', versions: 'v1.43.0' },
        { client: 'nimbus',     nodes: 14, first: '2026-06-25', versions: 'v26.6.2 (b2470f, 4a4ac9, 4973b0)' },
        { client: 'prysm',      nodes: 18, first: '2026-06-25', versions: 'v7.1.6 (9f03f0a, e733c6a)' },
        { client: 'teku',       nodes: 15, first: '2026-06-25', versions: 'v26.6.0+56-gac1c8c618f' }
    ];

    function fmtCount(n) {
        if (n >= 1e6) return (n / 1e6).toFixed(1) + 'M';
        if (n >= 1e3) return (n / 1e3).toFixed(0) + 'k';
        return n.toLocaleString();
    }
</script>

<PageMeta
    date="2026-07-10T06:00:00Z"
    author="samcm"
    tags={["glamsterdam", "gloas", "epbs", "xatu", "devnets"]}
    networks={["glamsterdam-devnet-6"]}
    startTime="2026-06-25T00:00:00Z"
    endTime="2026-07-09T23:59:59Z"
/>

<Section type="question">

## Question

Which consensus clients emit each of the new Glamsterdam (Gloas/ePBS) beacon API SSE events on glamsterdam-devnet-6?

</Section>

<Section type="background">

## Background

Glamsterdam added six new beacon API server-sent event types, captured into [new Xatu tables](https://ethpandaops.io/data/xatu/forks/glamsterdam/) as `beacon_api_eth_v1_events_*`. On glamsterdam-devnet-6 (genesis 2026-06-25, Gloas active from epoch 30) every node runs an xatu-sentry subscribed to its beacon node's event stream. Each client is watched by 14 to 18 independent sentries.

With that much redundancy, a zero cell means the client never emitted the event, not that we failed to collect it. One caveat: grandine sentries only came online on 2026-07-02, which still leaves a full week of Gloas-active observation.

<table class="matrix-table">
    <thead>
        <tr>
            <th style="text-align:left">client</th>
            <th>sentry nodes</th>
            <th>observing since</th>
            <th style="text-align:left">version(s) at window end</th>
        </tr>
    </thead>
    <tbody>
        {#each coverage as c}
        <tr>
            <td style="text-align:left"><b>{c.client}</b></td>
            <td style="text-align:center">{c.nodes}</td>
            <td style="text-align:center">{c.first}</td>
            <td style="text-align:left"><code>{c.versions}</code></td>
        </tr>
        {/each}
    </tbody>
</table>

<SqlSource source="xatu" query="glam_client_coverage" />

</Section>

<Section type="investigation">

## Investigation

### Event support matrix

A tick means the client emitted at least one event of this type over the window (2026-06-25 to 2026-07-09 UTC). Counts are total events across all of that client's sentries, from `glamsterdam-devnet-6.beacon_api_eth_v1_events_*`.

<table class="matrix-table">
    <thead>
        <tr>
            <th style="text-align:left">event</th>
            {#each clients as c}<th>{c}</th>{/each}
        </tr>
    </thead>
    <tbody>
        {#each matrix as row}
        <tr>
            <td style="text-align:left"><code>{row.event}</code></td>
            {#each row.cells as cnt}
            <td style="text-align:center">
                {#if cnt > 0}✅ <span class="cnt">{fmtCount(cnt)}</span>{:else}❌{/if}
            </td>
            {/each}
        </tr>
        {/each}
    </tbody>
</table>

<SqlSource source="xatu" query="glam_sse_client_matrix" />

Three gaps show up, and each one holds across every node of the affected client for the whole window:

- **nimbus** never emits `execution_payload_bid`.
- **grandine, lodestar and nimbus** never emit `payload_attestation`.
- **grandine and nimbus** never emit `proposer_preferences`.

These are API gaps, not networking gaps. The corresponding gossipsub topics show messages arriving from peers of every client, so nimbus does forward `execution_payload_bid` messages on gossip, it just doesn't expose the SSE event. Where a client does emit an event, its volume is in line with its node count. There are no partial or intermittent emitters.

</Section>

<Section type="takeaways">

## Takeaways

- **lighthouse, prysm and teku** emit all six new Glamsterdam SSE events.
- **grandine** is missing `payload_attestation` and `proposer_preferences`.
- **lodestar** is missing `payload_attestation`.
- **nimbus** is missing `execution_payload_bid`, `payload_attestation` and `proposer_preferences`.

</Section>

<style>
    .matrix-table {
        width: 100%;
        font-size: 0.85rem;
        border-collapse: collapse;
        margin: 1rem 0 1.5rem 0;
    }
    .matrix-table th, .matrix-table td {
        padding: 6px 8px;
        border-bottom: 1px solid rgba(128, 128, 128, 0.2);
    }
    .matrix-table .cnt {
        display: block;
        font-size: 0.7rem;
        opacity: 0.6;
    }
</style>
