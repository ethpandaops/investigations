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

    // head_v2 is not captured by Xatu yet; values are from the direct probes below.
    const headV2Row = { event: 'head_v2', cells: [false, false, false, false, true, true] };

    // Direct probes of every missing client/event pair, one node per client,
    // 2026-07-10: curl /eth/v1/events?topics=<topic> held open over SSH (20s, missing-but-accepted topics re-checked for 120s).
    // 'rejected' = HTTP 400, 'silent' = HTTP 200 but no events, 'emits' = events seen.
    const probes = [
        { client: 'grandine',   topic: 'head_v2',                     result: 'rejected', detail: '400: invalid query string: topics: Matching variant not found' },
        { client: 'grandine',   topic: 'payload_attestation_message', result: 'rejected', detail: '400: invalid query string: topics: Matching variant not found' },
        { client: 'grandine',   topic: 'proposer_preferences',        result: 'rejected', detail: '400: invalid query string: topics: Matching variant not found' },
        { client: 'lighthouse', topic: 'head_v2',                     result: 'rejected', detail: '400: BAD_REQUEST: unable to parse query' },
        { client: 'lodestar',   topic: 'head_v2',                     result: 'rejected', detail: '400: Invalid topic: head_v2' },
        { client: 'lodestar',   topic: 'payload_attestation_message', result: 'rejected', detail: '400: Invalid topic: payload_attestation_message' },
        { client: 'nimbus',     topic: 'head_v2',                     result: 'rejected', detail: '400: Invalid topics value' },
        { client: 'nimbus',     topic: 'execution_payload_bid',       result: 'silent',   detail: '200, no events in 120s' },
        { client: 'nimbus',     topic: 'payload_attestation_message', result: 'silent',   detail: '200, no events in 120s' },
        { client: 'nimbus',     topic: 'proposer_preferences',        result: 'silent',   detail: '200, no events in 120s' }
    ];
    const probeIcon = { silent: '⚠️', rejected: '❌' };

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
        <tr class="not-in-xatu">
            <td style="text-align:left"><code>{headV2Row.event}</code> <span class="badge">not in Xatu yet</span></td>
            {#each headV2Row.cells as ok}
            <td style="text-align:center">
                {#if ok}✅ <span class="cnt">probe</span>{:else}❌{/if}
            </td>
            {/each}
        </tr>
    </tbody>
</table>

<SqlSource source="xatu" query="glam_sse_client_matrix" />

Three gaps show up, and each one holds across every node of the affected client for the whole window:

- **nimbus** never emits `execution_payload_bid`.
- **grandine, lodestar and nimbus** never emit `payload_attestation`.
- **grandine and nimbus** never emit `proposer_preferences`.

These are API gaps, not networking gaps. The corresponding gossipsub topics show messages arriving from peers of every client, so nimbus does forward `execution_payload_bid` messages on gossip, it just doesn't expose the SSE event. Where a client does emit an event, its volume is in line with its node count. There are no partial or intermittent emitters.

The `head_v2` row is different from the rest: Glamsterdam added it to the event stream spec (it replaces the now-deprecated `head` event and adds `payload_status`) but Xatu does not capture it yet, so its row comes from the direct probes below rather than from Xatu data.

### Probing the gaps

To pin down what each missing cell actually means, we probed every missing client and event pair directly on 2026-07-10: one node per client, `curl /eth/v1/events?topics=<topic>` held open over SSH for 20 seconds, and 120 seconds (10 slots) wherever the stream stayed silent. The same probe against prysm and teku is what fills the `head_v2` row in the matrix above; both emit it with `payload_status` immediately. Note the SSE topic for payload attestations is `payload_attestation_message` per the spec; Xatu just stores it as `payload_attestation`.

<table class="matrix-table">
    <thead>
        <tr>
            <th style="text-align:left">client</th>
            <th style="text-align:left">topic</th>
            <th>result</th>
            <th style="text-align:left">response</th>
        </tr>
    </thead>
    <tbody>
        {#each probes as p}
        <tr>
            <td style="text-align:left"><b>{p.client}</b></td>
            <td style="text-align:left"><code>{p.topic}</code></td>
            <td style="text-align:center">{probeIcon[p.result]} <span class="cnt">{p.result}</span></td>
            <td style="text-align:left"><code>{p.detail}</code></td>
        </tr>
        {/each}
    </tbody>
</table>

The probes split the gaps into two kinds:

- **grandine and lodestar reject** their missing topics with a 400: the topics don't exist in their event stream API at all.
- **nimbus accepts** subscriptions to all three of its missing topics but never sends an event, even over 10 slots. The API routing exists; the emission doesn't. Its `head_v2` rejection is the exception.

All six clients still emit the deprecated v1 `head` event.

</Section>

<Section type="takeaways">

## Takeaways

- **lighthouse, prysm and teku** emit all six new Glamsterdam SSE events.
- **grandine** is missing `payload_attestation` and `proposer_preferences`.
- **lodestar** is missing `payload_attestation`.
- **nimbus** is missing `execution_payload_bid`, `payload_attestation` and `proposer_preferences`.
- `head_v2` is only emitted by **prysm** and **teku**; the other four clients reject the topic. Xatu doesn't capture it yet either.
- Probing the gaps directly: grandine and lodestar reject their missing topics with a 400, while nimbus accepts the subscription but never emits.

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
    .not-in-xatu {
        background: rgba(234, 179, 8, 0.08);
    }
    .badge {
        display: inline-block;
        margin-left: 0.4rem;
        padding: 0.05rem 0.4rem;
        border: 1px solid rgba(234, 179, 8, 0.6);
        border-radius: 999px;
        font-size: 0.65rem;
        color: #a16207;
        white-space: nowrap;
        vertical-align: middle;
    }
    :global([data-theme="dark"]) .badge {
        color: #eab308;
    }
</style>
