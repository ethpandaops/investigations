---
title: XEN Mint Waves and Client newPayload Divergence
sidebar_position: 1
description: A XEN batch-mint spam wave made geth, nethermind, reth and besu 2-3x slower at newPayload while ethrex didn't flinch — same gas, very different pain
date: 2026-07-10T06:00:00Z
author: samcm
tags:
  - eip-7870
  - newpayload
  - execution-clients
  - xen
  - state-growth
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts, DataTable, Column } from '@evidence-dev/core-components';

    // Fixed color per client across every chart (validated categorical palette)
    const CLIENT_ORDER = ['go-ethereum', 'Reth', 'ethrex', 'Nethermind', 'Besu', 'erigon'];
    const CLIENT_COLORS = {
        'go-ethereum': '#2563eb',
        'Reth': '#ea580c',
        'ethrex': '#16a34a',
        'Nethermind': '#9333ea',
        'Besu': '#0891b2',
        'erigon': '#a16207'
    };
    const C_XEN = '#dc2626';
    const C_CLEAN = '#9ca3af';

    const lineFor = (name, data) => ({
        name,
        type: 'line',
        data,
        showSymbol: false,
        lineStyle: { width: name === 'ethrex' ? 3 : 2, color: CLIENT_COLORS[name] },
        itemStyle: { color: CLIENT_COLORS[name] }
    });

    // Chart 1: hourly p50 per client, utility cluster, Jul 8-10
    $: hourlyConfig = (() => {
        if (!np_hourly || np_hourly.length === 0 || np_hourly[0].hour_label == null) return {};
        const rows = np_hourly.filter(d => d.cluster === 'utility');
        const hours = [...new Set(rows.map(d => d.hour_label))];
        const els = CLIENT_ORDER.filter(el => rows.some(d => d.el === el));
        const byEl = {};
        rows.forEach(d => {
            if (!byEl[d.el]) byEl[d.el] = {};
            byEl[d.el][d.hour_label] = Number(d.p50_ms);
        });
        return {
            title: { text: 'newPayload p50 by Client — utility 7870 nodes', subtext: 'Hourly median of VALID responses, 2026-07-08 to 2026-07-10 UTC', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', valueFormatter: v => (v == null ? 'n/a' : Number(v).toFixed(0) + 'ms') },
            legend: { data: els, top: 44, type: 'scroll' },
            grid: { left: 12, right: 22, bottom: 70, top: 92, containLabel: true },
            xAxis: { type: 'category', data: hours, axisLabel: { interval: 3, rotate: 45, fontSize: 9 }, name: 'Hour (UTC)', nameLocation: 'center', nameGap: 55 },
            yAxis: { type: 'value', name: 'p50 duration (ms)', nameLocation: 'center', nameGap: 42, nameRotate: 90 },
            series: els.map(el => lineFor(el, hours.map(h => byEl[el]?.[h] ?? null)))
        };
    })();

    // Chart 2: same client (geth), three clusters — rules out hardware
    $: clusterConfig = (() => {
        if (!np_hourly || np_hourly.length === 0 || np_hourly[0].hour_label == null) return {};
        const rows = np_hourly.filter(d => d.el === 'go-ethereum');
        const hours = [...new Set(np_hourly.map(d => d.hour_label))];
        const clusters = ['utility', 'sigma', 'berlin'].filter(c => rows.some(d => d.cluster === c));
        const colors = { utility: '#2563eb', sigma: '#ea580c', berlin: '#6b7280' };
        const byCluster = {};
        rows.forEach(d => {
            if (!byCluster[d.cluster]) byCluster[d.cluster] = {};
            byCluster[d.cluster][d.hour_label] = Number(d.p50_ms);
        });
        return {
            title: { text: 'Same Client, Three Datacenters — geth', subtext: 'Hourly newPayload p50 per cluster. The spike hits all clusters at once, so it is not hardware.', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', valueFormatter: v => (v == null ? 'n/a' : Number(v).toFixed(0) + 'ms') },
            legend: { data: clusters, top: 44 },
            grid: { left: 12, right: 22, bottom: 70, top: 92, containLabel: true },
            xAxis: { type: 'category', data: hours, axisLabel: { interval: 3, rotate: 45, fontSize: 9 }, name: 'Hour (UTC)', nameLocation: 'center', nameGap: 55 },
            yAxis: { type: 'value', name: 'p50 duration (ms)', nameLocation: 'center', nameGap: 42, nameRotate: 90 },
            series: clusters.map(c => ({
                name: c, type: 'line', showSymbol: false,
                data: hours.map(h => byCluster[c]?.[h] ?? null),
                lineStyle: { width: 2, color: colors[c] }, itemStyle: { color: colors[c] }
            }))
        };
    })();

    // Chart 3: 5-minute zoom, utility, incident window
    $: zoomConfig = (() => {
        if (!np_5min || np_5min.length === 0 || np_5min[0].bucket_label == null) return {};
        const buckets = [...new Set(np_5min.map(d => d.bucket_label))];
        const els = CLIENT_ORDER.filter(el => np_5min.some(d => d.el === el));
        const byEl = {};
        np_5min.forEach(d => {
            if (!byEl[d.el]) byEl[d.el] = {};
            byEl[d.el][d.bucket_label] = Number(d.p50_ms);
        });
        return {
            title: { text: 'The Bursts Up Close — utility, 08:00-12:00 UTC', subtext: '5-minute newPayload p50. Waves of ~10-25 minutes with sharp returns to baseline.', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', valueFormatter: v => (v == null ? 'n/a' : Number(v).toFixed(0) + 'ms') },
            legend: { data: els, top: 44, type: 'scroll' },
            grid: { left: 12, right: 22, bottom: 60, top: 92, containLabel: true },
            xAxis: { type: 'category', data: buckets, axisLabel: { interval: 5, rotate: 45, fontSize: 9 }, name: 'Time (UTC)', nameLocation: 'center', nameGap: 45 },
            yAxis: { type: 'value', name: 'p50 duration (ms)', nameLocation: 'center', nameGap: 42, nameRotate: 90 },
            series: els.map(el => lineFor(el, buckets.map(b => byEl[el]?.[b] ?? null)))
        };
    })();

    // Chart 4: workload was flat — avg mgas per 5-min bucket
    $: workloadConfig = (() => {
        if (!workload_5min || workload_5min.length === 0 || workload_5min[0].bucket_label == null) return {};
        const buckets = workload_5min.map(d => d.bucket_label);
        return {
            title: { text: 'Meanwhile, the Workload Never Moved', subtext: 'Average gas per block in the same 5-minute buckets — flat at ~30 Mgas throughout', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', valueFormatter: v => Number(v).toFixed(1) + ' Mgas' },
            grid: { left: 12, right: 22, bottom: 60, top: 70, containLabel: true },
            xAxis: { type: 'category', data: buckets, axisLabel: { interval: 5, rotate: 45, fontSize: 9 }, name: 'Time (UTC)', nameLocation: 'center', nameGap: 45 },
            yAxis: { type: 'value', name: 'Avg gas per block (Mgas)', nameLocation: 'center', nameGap: 40, nameRotate: 90, max: 60 },
            series: [{
                name: 'Avg Mgas/block', type: 'bar', barCategoryGap: '20%',
                data: workload_5min.map(d => Number(d.avg_mgas)),
                itemStyle: { color: '#2563eb', borderRadius: [4, 4, 0, 0] }
            }]
        };
    })();

    // Chart 5: grouped bar — median duration with vs without XEN txs, per client
    $: actorSplitConfig = (() => {
        if (!actor_split || actor_split.length === 0 || actor_split[0].el == null) return {};
        const els = CLIENT_ORDER.filter(el => actor_split.some(d => d.el === el));
        const withXen = els.map(el => { const r = actor_split.find(d => d.el === el && d.grp === 'with_xen'); return r ? Number(r.med_ms) : null; });
        const without = els.map(el => { const r = actor_split.find(d => d.el === el && d.grp === 'clean'); return r ? Number(r.med_ms) : null; });
        return {
            title: { text: 'Same Minutes, Split by Block Content', subtext: 'Median newPayload duration during the spike (09:00-11:00 UTC), utility nodes', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: v => (v == null ? 'n/a' : Number(v).toFixed(0) + 'ms') },
            legend: { data: ['Block contains XEN mint tx', 'Clean block'], top: 44 },
            grid: { left: 12, right: 22, bottom: 50, top: 92, containLabel: true },
            xAxis: { type: 'category', data: els, name: 'Execution client', nameLocation: 'center', nameGap: 32 },
            yAxis: { type: 'value', name: 'Median duration (ms)', nameLocation: 'center', nameGap: 42, nameRotate: 90 },
            series: [
                { name: 'Block contains XEN mint tx', type: 'bar', data: withXen, itemStyle: { color: C_XEN, borderRadius: [4, 4, 0, 0] }, barGap: '10%', label: { show: true, position: 'top', fontSize: 10, formatter: p => p.value + 'ms' } },
                { name: 'Clean block', type: 'bar', data: without, itemStyle: { color: C_CLEAN, borderRadius: [4, 4, 0, 0] }, label: { show: true, position: 'top', fontSize: 10, formatter: p => p.value + 'ms' } }
            ]
        };
    })();

    // Chart 6: scatter small-multiples — duration vs block gas, geth and ethrex
    const scatterFor = (rows, title, msCol) => {
        if (!rows || rows.length === 0 || rows[0].block_number == null) return {};
        const mk = (pred) => rows.filter(pred).map(d => [Number(d.mgas), Number(d[msCol])]);
        return {
            title: { text: title, left: 'center', textStyle: { fontSize: 13, fontWeight: 600 } },
            tooltip: { trigger: 'item', formatter: p => `${p.value[0]} Mgas → ${p.value[1]}ms` },
            legend: { data: ['Contains XEN mint tx', 'Clean block'], top: 28 },
            grid: { left: 12, right: 18, bottom: 50, top: 66, containLabel: true },
            xAxis: { type: 'value', name: 'Block gas (Mgas)', nameLocation: 'center', nameGap: 30, max: 60 },
            yAxis: { type: 'value', name: 'newPayload (ms)', nameLocation: 'center', nameGap: 40, nameRotate: 90, max: 300 },
            series: [
                { name: 'Contains XEN mint tx', type: 'scatter', symbolSize: 7, data: mk(d => Number(d.actor_mgas) > 0), itemStyle: { color: C_XEN, opacity: 0.75 } },
                { name: 'Clean block', type: 'scatter', symbolSize: 7, data: mk(d => Number(d.actor_mgas) === 0), itemStyle: { color: C_CLEAN, opacity: 0.75 } }
            ]
        };
    };
    $: gethScatterConfig = scatterFor(blocks_joined, 'geth: XEN blocks off the trend', 'geth_ms');
    $: ethrexScatterConfig = scatterFor(blocks_joined, 'ethrex: XEN blocks on the trend', 'ethrex_ms');

    // Chart 7: opcode profile — horizontal bar
    $: opcodeConfig = (() => {
        if (!opcode_profile || opcode_profile.length === 0 || opcode_profile[0].operation == null) return {};
        const rows = [...opcode_profile].sort((a, b) => Number(a.mgas_self) - Number(b.mgas_self));
        return {
            title: { text: 'Where the Gas Goes in a XEN Mint Tx', subtext: 'Self gas by opcode, 30 largest CoinTool batch-mint txs (~204 Mgas total)', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (ps) => { const d = ps[0]; const row = rows[d.dataIndex]; return `<b>${d.name}</b><br/>Self gas: ${Number(d.value).toFixed(1)} Mgas<br/>Count: ${Number(row?.op_count).toLocaleString()}<br/>Cold accesses: ${Number(row?.cold_accesses).toLocaleString()}`; } },
            grid: { left: 12, right: 44, bottom: 50, top: 70, containLabel: true },
            xAxis: { type: 'value', name: 'Self gas (Mgas)', nameLocation: 'center', nameGap: 30 },
            yAxis: { type: 'category', data: rows.map(d => d.operation) },
            series: [{
                type: 'bar', barMaxWidth: 22,
                data: rows.map(d => ({
                    value: Number(d.mgas_self),
                    itemStyle: { color: (d.operation === 'SSTORE' || d.operation === 'SLOAD') ? C_XEN : '#2563eb', borderRadius: [0, 4, 4, 0] }
                })),
                label: { show: true, position: 'right', fontSize: 9, formatter: p => Number(p.value).toFixed(1) }
            }]
        };
    })();

    // Chart 8: campaign history
    $: campaignConfig = (() => {
        if (!campaign_history || campaign_history.length === 0 || campaign_history[0].approx_date == null) return {};
        const days = campaign_history.map(d => new Date(d.approx_date).toISOString().slice(0, 10));
        return {
            title: { text: 'This Was Not a One-Off', subtext: 'Daily gas consumed by the three XEN batch-mint contracts (dates approximated from block numbers)', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', valueFormatter: v => Number(v).toFixed(1) + ' Ggas' },
            grid: { left: 12, right: 22, bottom: 60, top: 70, containLabel: true },
            xAxis: { type: 'category', data: days, axisLabel: { rotate: 45, fontSize: 9 }, name: 'Date (approx, UTC)', nameLocation: 'center', nameGap: 55 },
            yAxis: { type: 'value', name: 'Gas per day (Ggas)', nameLocation: 'center', nameGap: 40, nameRotate: 90 },
            series: [{
                name: 'XEN mint gas', type: 'bar',
                data: campaign_history.map(d => Number(d.ggas)),
                itemStyle: { color: '#2563eb', borderRadius: [4, 4, 0, 0] }
            }]
        };
    })();
</script>

<PageMeta
    date="2026-07-10T06:00:00Z"
    author="samcm"
    tags={["eip-7870", "newpayload", "execution-clients", "xen", "state-growth"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-07-08T00:00:00Z"
    endTime="2026-07-10T00:00:00Z"
/>

```sql np_hourly
select * from xatu.xen_np_hourly order by hour, cluster, el
```

```sql np_5min
select * from xatu.xen_np_5min order by bucket, el
```

```sql workload_5min
select * from xatu.xen_workload_5min order by bucket
```

```sql blocks_joined
select
    d.block_number,
    d.mgas,
    d.geth_ms, d.nethermind_ms, d.reth_ms, d.ethrex_ms, d.besu_ms, d.erigon_ms,
    coalesce(a.actor_mgas, 0) as actor_mgas,
    coalesce(a.actor_txs, 0) as actor_txs
from xatu.xen_block_durations d
left join xatu.xen_actor_blocks a on d.block_number = a.block_number
```

```sql actor_split
with joined as (
    select
        case when coalesce(a.actor_mgas, 0) > 0 then 'with_xen' else 'clean' end as grp,
        d.*
    from xatu.xen_block_durations d
    left join xatu.xen_actor_blocks a on d.block_number = a.block_number
)
select el, grp, round(median(ms), 0) as med_ms, count(*) as blocks
from (
    select grp, 'go-ethereum' as el, geth_ms as ms from joined
    union all select grp, 'Nethermind', nethermind_ms from joined
    union all select grp, 'Reth', reth_ms from joined
    union all select grp, 'ethrex', ethrex_ms from joined
    union all select grp, 'Besu', besu_ms from joined
    union all select grp, 'erigon', erigon_ms from joined
)
where ms > 0
group by el, grp
order by el, grp
```

```sql small_slow
select
    d.block_number,
    d.mgas,
    coalesce(a.actor_mgas, 0) as actor_mgas,
    coalesce(a.actor_txs, 0) as actor_txs,
    d.geth_ms, d.nethermind_ms, d.reth_ms, d.ethrex_ms
from xatu.xen_block_durations d
left join xatu.xen_actor_blocks a on d.block_number = a.block_number
where d.mgas < 20 and d.nethermind_ms > 80
order by d.block_number
```

```sql throughput_pivot
select
    el,
    max(case when period = 'baseline' then p50_ms end) as baseline_p50_ms,
    max(case when period = 'spike' then p50_ms end) as spike_p50_ms,
    max(case when period = 'baseline' then p50_mgas_per_s end) as baseline_mgas_s,
    max(case when period = 'spike' then p50_mgas_per_s end) as spike_mgas_s,
    round(100.0 * (1 - max(case when period = 'spike' then p50_mgas_per_s end)
        / max(case when period = 'baseline' then p50_mgas_per_s end)), 0) as throughput_drop_pct
from xatu.xen_throughput
group by el
order by throughput_drop_pct desc
```

```sql side_check_pivot
select
    el,
    max(case when side = 'CL (tysm)' and period = 'baseline' then p50_ms end) as cl_baseline_ms,
    max(case when side = 'CL (tysm)' and period = 'spike' then p50_ms end) as cl_spike_ms,
    max(case when side = 'EL (snooper)' and period = 'baseline' then p50_ms end) as el_baseline_ms,
    max(case when side = 'EL (snooper)' and period = 'spike' then p50_ms end) as el_spike_ms
from xatu.xen_side_check
group by el
order by el
```

```sql opcode_profile
select * from xatu.xen_opcode_profile
```

```sql campaign_history
select * from xatu.xen_campaign_history order by approx_date
```

<Section type="question">

## Question

On 2026-07-09, geth, nethermind, reth and besu all slowed down 2-3x on the EIP-7870 reference nodes while ethrex stayed completely flat. Was it hardware, broken metrics, or something in the blocks?

</Section>

<Section type="background">

## Background

The [EIP-7870](https://eips.ethereum.org/EIPS/eip-7870) fleet runs every major execution client on identical reference hardware (Hetzner AX52) across three independent datacenters — `utility`, `sigma` and `berlin`. Each node pairs an EL with [tysm](https://github.com/ethpandaops/tysm), which times every `engine_newPayload` call and ships the measurement to Xatu (`consensus_engine_api_new_payload`). An [engine snooper](https://github.com/ethpandaops/xatu) sitting between CL and EL independently records the same calls from the EL side (`execution_engine_new_payload`).

A report came in that reth, nethermind and geth were "underperforming" on the [7870 deep-dive dashboard](https://grafana.observability.ethpandaops.io/d/eip7870-node-deep-dive/eip-7870-node-deep-dive) — but ethrex wasn't. Three candidate explanations, in rough order of prior probability:

1. **Hardware** — noisy neighbors, disk trouble, one bad datacenter
2. **Broken metrics** — tysm not actually measuring execution time
3. **Workload** — the blocks themselves changed in some way that hurts clients unevenly

**Data range**: 2026-07-08 00:00 to 2026-07-10 00:00 UTC, mainnet, blocks 25,493,987-25,494,583 for the per-block analysis.

</Section>

<Section type="investigation">

## Investigation

### When It Happened

The anomaly is a two-hour window on 2026-07-09 from roughly 08:45 to 10:45 UTC. Four clients — geth, nethermind, reth, besu — roughly doubled-to-tripled their median newPayload duration. Ethrex did not move. Erigon barely moved.

<SqlSource source="xatu" query="xen_np_hourly" />

<ECharts config={hourlyConfig} height="440px" />

### Ruling Out Hardware

The three clusters are independent machines in independent datacenters. If this were hardware, the spike would live in one cluster. It doesn't — the same client spikes in all three at the same minute and recovers at the same minute.

<ECharts config={clusterConfig} height="400px" />

The berlin trace ends on 2026-07-10 because those nodes were removed for unrelated reasons (they also ran ~2x slower after a fresh resync on the evening of Jul 9 — cold caches, not this event).

### Ruling Out the Metrics

tysm measures from the CL side of the Engine API. The snooper measures from the EL side. If tysm were misreporting, the two would disagree. They don't:

<SqlSource source="xatu" query="xen_side_check" />

<DataTable data={side_check_pivot}>
    <Column id="el" title="Client" />
    <Column id="cl_baseline_ms" title="CL-side baseline (ms)" />
    <Column id="cl_spike_ms" title="CL-side spike (ms)" />
    <Column id="el_baseline_ms" title="EL-side baseline (ms)" />
    <Column id="el_spike_ms" title="EL-side spike (ms)" />
</DataTable>

Both capture points agree to within a few milliseconds: ethrex 32ms in both periods on both sides, everyone else elevated during the spike. The status mix was also clean — no burst of `SYNCING` or `ERROR` responses hiding slow calls from the VALID-only median.

### The Workload That Wasn't There

The obvious workload suspects come up empty. Average gas per block sat at ~30 Mgas the entire time. Transaction counts and blob counts were normal. Mempool volume showed no burst matching the slow windows.

<ECharts config={zoomConfig} height="420px" />

<SqlSource source="xatu" query="xen_workload_5min" />

<ECharts config={workloadConfig} height="300px" />

Same gas, same transaction counts — but bursts of 10-25 minutes where four clients pay a large fixed overhead on every block. That on/off shape is the signature of *something in specific blocks*, not background load.

### Splitting Blocks by Content

The spike-window blocks divide cleanly into two populations: blocks containing transactions to three XEN batch-mint contracts, and blocks without them. The contracts are [CoinTool: XEN Batch Minter](https://etherscan.io/address/0x0de8bf93da2f7eecb3d9169422413a9bef4ef628) (`0x0de8bf...`), [MCT XENFT](https://etherscan.io/address/0x0000000000771a79d0fc7f3b7fe270eb4498f20b) (`0x000000...`) and [MCT-XEN Batch Minter](https://etherscan.io/address/0x2f848984984d6c3c036174ce627703edaf780479) (`0x2f8489...`) — 6.8 to 15.4 Mgas per transaction, from about five sender addresses.

<SqlSource source="xatu" query="xen_block_durations" />
<SqlSource source="xatu" query="xen_actor_blocks" />

<ECharts config={actorSplitConfig} height="420px" />

During the *same minutes*, clean blocks executed at normal speed on every client. Only blocks carrying XEN mint transactions were slow — and only for four of the six clients.

The per-block scatter makes the mechanism visible. For geth, XEN blocks sit far above the gas trend line — a ~13 Mgas block with one 6.8 Mgas mint tx costs as much as a full 60 Mgas block. For ethrex, XEN blocks sit exactly on the trend:

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
<ECharts config={gethScatterConfig} height="360px" />
<ECharts config={ethrexScatterConfig} height="360px" />
</div>

The starkest view: small blocks (under 20 Mgas) that were nonetheless slow for nethermind. Nearly all contain exactly one XEN mint transaction. That single transaction adds 60-100ms for geth/nethermind/reth and ~5ms for ethrex:

<DataTable data={small_slow} rows=20>
    <Column id="block_number" title="Block" fmt="id" />
    <Column id="mgas" title="Block Mgas" />
    <Column id="actor_txs" title="XEN txs" />
    <Column id="actor_mgas" title="XEN Mgas" />
    <Column id="geth_ms" title="geth (ms)" />
    <Column id="nethermind_ms" title="nethermind (ms)" />
    <Column id="reth_ms" title="reth (ms)" />
    <Column id="ethrex_ms" title="ethrex (ms)" />
</DataTable>

### What a XEN Mint Actually Does

Execution traces of the 30 largest CoinTool mint transactions show where the gas goes. Per ~6.8 Mgas transaction: roughly 1,900 `SSTORE`s, 2,100 `SLOAD`s (about 700 of them cold), DELEGATECALL fan-out to ~600 minimal proxies, and millions of cheap interpreter opcodes.

<SqlSource source="xatu" query="xen_opcode_profile" />

<ECharts config={opcodeConfig} height="440px" />

This is a state-stress workload: gas pays linearly for storage touches, but the real cost — cold trie reads, dirty-node accumulation, state-root recomputation — scales with how scattered those touches are. Thirty Mgas of XEN mints is far more expensive to merkleize than thirty Mgas of swaps, and clients whose state layout amortizes that work (flat state layouts, different trie-commit strategies) barely notice. Ethrex processed XEN blocks at its normal ~1.05 ms/Mgas; erigon's penalty was also small. The others paid heavily:

<SqlSource source="xatu" query="xen_throughput" />

<DataTable data={throughput_pivot}>
    <Column id="el" title="Client" />
    <Column id="baseline_p50_ms" title="Baseline p50 (ms)" />
    <Column id="spike_p50_ms" title="Spike p50 (ms)" />
    <Column id="baseline_mgas_s" title="Baseline throughput (Mgas/s)" />
    <Column id="spike_mgas_s" title="Spike throughput (Mgas/s)" />
    <Column id="throughput_drop_pct" title="Throughput drop (%)" />
</DataTable>

One deferral check for ethrex: if it were postponing the trie work (returning VALID fast and paying later), the *next* block after a XEN block would be slow. It isn't — blocks following XEN blocks run at the same 26ms median as any other clean block.

### Why Bursts, and Why Now

XEN minting is profitable only when gas is cheap. Base fees sat at 0.07-0.14 gwei through the incident window — prime minting conditions — and the wave stopped as fees climbed past ~0.15 gwei after midday. The campaign itself is not new: these three contracts have burned gas continuously for weeks, peaking near 60 Ggas/day in late June. Any chart of client execution performance over that period will carry the same fingerprint.

<SqlSource source="xatu" query="xen_campaign_history" />

<ECharts config={campaignConfig} height="360px" />

</Section>

<Section type="takeaways">

## Takeaways

- The 2026-07-09 divergence was **real client behavior under a XEN batch-mint spam wave** (08:45-10:45 UTC) — not hardware (identical spike in three independent datacenters) and not metrics (CL-side and EL-side measurements agree exactly).
- Total gas explains nothing here: blocks averaged ~30 Mgas throughout. **Block content is what changed** — each mint tx does ~1,900 SSTOREs and ~700 cold SLOADs via proxy fan-out, a worst-case state-access pattern per unit of gas.
- A single 6.8 Mgas mint transaction added **60-100ms** to geth, nethermind and reth, and **~5ms** to ethrex. Gas-normalized throughput dropped 23-38% for geth/nethermind/reth/besu while ethrex was unchanged.
- **ethrex and erigon are architecturally resilient** to this workload; the result is worth flagging to client teams on both sides of the gap — it is exactly the divergence that matters for gas-limit-increase discussions, since gas is supposed to price this work.
- The XEN campaign is ongoing and fires whenever base fee dips below ~0.15 gwei. Expect the same fingerprint in past and future performance charts; per-block content splits (this page's method) separate it from genuine client regressions.

</Section>
