---
title: Block Size vs. Propagation on Mainnet
sidebar_position: 1
description: How much does payload size actually slow down block propagation? Most of the apparent effect turns out to be MEV-Boost release timing, not gossipsub bandwidth.
date: 2026-05-06T00:00:00Z
author: samcm
tags:
  - propagation
  - gossipsub
  - block-size
  - mev-boost
  - eip-7870
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // Per-source row projections for the two lookup tables
    $: mev_rows = (dispersion_lookup || []).map(d => ({
        size_bin:    d.size_bin,
        avg_pre_kb:  d.avg_pre_kb,
        n:           d.mev_n,
        p50:         d.mev_p50,
        p75:         d.mev_p75,
        p95:         d.mev_p95,
        p99:         d.mev_p99,
    }));
    $: local_rows = (dispersion_lookup || []).map(d => ({
        size_bin:    d.size_bin,
        avg_pre_kb:  d.avg_pre_kb,
        n:           d.local_n,
        p50:         d.local_p50,
        p75:         d.local_p75,
        p95:         d.local_p95,
        p99:         d.local_p99,
    }));

    // ---- Chart 1: Naive view (ready time vs size from slot start) ----
    $: naiveConfig = (() => {
        if (!naive_view || naive_view.length === 0) return {};
        const x = naive_view.map(d => Number(d.bin_mid_kb));
        return {
            title: { text: 'Time to be seen, measured from slot start', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis', formatter: (params) => {
                let s = `<b>~${params[0].axisValue} KB post-snappy</b><br/>`;
                params.forEach(p => { s += `${p.marker} ${p.seriesName}: ${Number(p.value).toFixed(0)} ms<br/>`; });
                return s;
            }},
            grid: { left: 70, right: 30, bottom: 60, top: 60 },
            xAxis: { type: 'category', data: x, name: 'post-snappy block size (KB), the wire format', nameLocation: 'center', nameGap: 35 },
            yAxis: { type: 'value', name: 'ms from slot start', nameLocation: 'center', nameGap: 50, nameRotate: 90, max: 4500 },
            legend: { data: ['p50', 'p95', 'p99'], top: 30 },
            series: [
                { name: 'p50', type: 'line', data: naive_view.map(d => Number(d.p50_seen_ms)), itemStyle: { color: '#16a34a' }, lineStyle: { color: '#16a34a', width: 3 }, symbol: 'circle' },
                { name: 'p95', type: 'line', data: naive_view.map(d => Number(d.p95_seen_ms)), itemStyle: { color: '#dc2626' }, lineStyle: { color: '#dc2626', width: 2 }, symbol: 'rect' },
                { name: 'p99', type: 'line', data: naive_view.map(d => Number(d.p99_seen_ms)), itemStyle: { color: '#000000' }, lineStyle: { color: '#000000', width: 2, type: 'dashed' }, symbol: 'triangle',
                  markLine: { silent: true, symbol: 'none',
                    label: { show: true, position: 'insideEndTop', formatter: '4s attestation deadline' },
                    lineStyle: { type: 'dashed', color: '#dc2626' },
                    data: [{ yAxis: 4000 }]
                  }
                }
            ]
        };
    })();

    // ---- Chart 2: Pure dispersion vs size ----
    $: dispersionConfig = (() => {
        if (!pure_dispersion || pure_dispersion.length === 0) return {};
        const x = pure_dispersion.map(d => Number(d.bin_mid_kb));
        return {
            title: { text: 'Pure mesh dispersion (after first network sighting)', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis', formatter: (params) => {
                let s = `<b>~${params[0].axisValue} KB post-snappy</b><br/>`;
                params.forEach(p => { s += `${p.marker} ${p.seriesName}: ${Number(p.value).toFixed(0)} ms<br/>`; });
                return s;
            }},
            grid: { left: 70, right: 30, bottom: 60, top: 60 },
            xAxis: { type: 'category', data: x, name: 'post-snappy block size (KB)', nameLocation: 'center', nameGap: 35 },
            yAxis: { type: 'value', name: 'dispersion after first sighting (ms)', nameLocation: 'center', nameGap: 60, nameRotate: 90 },
            legend: { data: ['p50', 'p75', 'p95', 'p99'], top: 30 },
            series: [
                { name: 'p50', type: 'line', data: pure_dispersion.map(d => Number(d.p50_disp_ms)), itemStyle: { color: '#16a34a' }, lineStyle: { color: '#16a34a', width: 3 }, symbol: 'circle' },
                { name: 'p75', type: 'line', data: pure_dispersion.map(d => Number(d.p75_disp_ms)), itemStyle: { color: '#3b82f6' }, lineStyle: { color: '#3b82f6', width: 2 }, symbol: 'rect' },
                { name: 'p95', type: 'line', data: pure_dispersion.map(d => Number(d.p95_disp_ms)), itemStyle: { color: '#dc2626' }, lineStyle: { color: '#dc2626', width: 2 }, symbol: 'triangle' },
                { name: 'p99', type: 'line', data: pure_dispersion.map(d => Number(d.p99_disp_ms)), itemStyle: { color: '#000000' }, lineStyle: { color: '#000000', width: 2, type: 'dashed' }, symbol: 'diamond' }
            ]
        };
    })();

    // ---- Chart 3: Dispersion split by source (lines from the wide lookup query) ----
    $: bySourceConfig = (() => {
        if (!dispersion_lookup || dispersion_lookup.length === 0) return {};
        const x = dispersion_lookup.map(d => d.size_bin);
        return {
            title: { text: 'Pure dispersion: MEV-Boost vs locally-built blocks', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis', formatter: (params) => {
                let s = `<b>${params[0].axisValue}</b><br/>`;
                params.forEach(p => { s += `${p.marker} ${p.seriesName}: ${Number(p.value).toFixed(0)} ms<br/>`; });
                return s;
            }},
            grid: { left: 70, right: 130, bottom: 80, top: 60 },
            xAxis: { type: 'category', data: x, name: 'post-snappy block size', nameLocation: 'center', nameGap: 50,
                axisLabel: { rotate: 30, fontSize: 10 } },
            yAxis: { type: 'value', name: 'dispersion after first sighting (ms)', nameLocation: 'center', nameGap: 60, nameRotate: 90 },
            legend: { data: ['MEV-Boost p50', 'Local p50', 'MEV-Boost p95', 'Local p95'], right: 10, orient: 'vertical', top: 'center' },
            series: [
                { name: 'MEV-Boost p50', type: 'line', data: dispersion_lookup.map(d => Number(d.mev_p50)),   itemStyle: { color: '#3b82f6' }, lineStyle: { color: '#3b82f6', width: 3 }, symbol: 'circle' },
                { name: 'Local p50',     type: 'line', data: dispersion_lookup.map(d => Number(d.local_p50)), itemStyle: { color: '#16a34a' }, lineStyle: { color: '#16a34a', width: 3 }, symbol: 'circle' },
                { name: 'MEV-Boost p95', type: 'line', data: dispersion_lookup.map(d => Number(d.mev_p95)),   itemStyle: { color: '#3b82f6' }, lineStyle: { color: '#3b82f6', width: 2, type: 'dashed' }, symbol: 'rect' },
                { name: 'Local p95',     type: 'line', data: dispersion_lookup.map(d => Number(d.local_p95)), itemStyle: { color: '#16a34a' }, lineStyle: { color: '#16a34a', width: 2, type: 'dashed' }, symbol: 'rect' }
            ]
        };
    })();
</script>

<PageMeta
    date="2026-05-06T00:00:00Z"
    author="samcm"
    tags={["propagation", "gossipsub", "block-size", "mev-boost", "eip-7870"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-04-25T00:00:00Z"
    endTime="2026-05-02T00:00:00Z"
/>

```sql headline
select * from xatu_cbt.bsp_headline
```

```sql naive_view
select * from xatu_cbt.bsp_naive_view
```

```sql pure_dispersion
select * from xatu_cbt.bsp_pure_dispersion
```

```sql dispersion_lookup
select * from xatu_cbt.bsp_dispersion_lookup
```

<Section type="question">

## Question

When a block on Ethereum mainnet gets bigger, how much longer does it actually take to disseminate across the gossipsub mesh? And do MEV-Boost relays disperse blocks any faster than a regular proposer publishing into its own mesh?

</Section>

<Section type="background">

## Background

A block is propagated on the consensus-layer p2p network as one **gossipsub** message: the full signed beacon block, SSZ-encoded then snappy-compressed (`ssz_snappy`). The compressed payload is what hits the wire. Every node in the gossipsub mesh receives the bytes, validates the message at the consensus level (proposer signature, parent seen, slot, etc.), and forwards it to its peers. Per the [bellatrix p2p-interface spec](https://github.com/ethereum/consensus-specs/blob/dev/specs/bellatrix/p2p-interface.md), execution-payload validity is **not** required for gossip propagation, so `newPayload` doesn't sit in the dissemination hot path. This investigation focuses on dissemination only.

**A note on the time origin.** When a sentry first sees a block over gossipsub, two things happened: the block was *released* into the network at some point in the slot, then it *dispersed* through the gossipsub mesh until it reached the sentry. Measuring from slot start mixes these. The release-into-network time is dominated by builder behavior (especially MEV-Boost relay deadlines, which cluster blocks into late-slot cohorts), not by the network. So to study the network we use `t_first`, the earliest sighting of the block by *any* Xatu sentry, as the time origin and look at how long after that each individual sentry saw it. This isolates pure mesh dispersion from release timing.

The data window is **2026-04-25 to 2026-05-02** (7 days, 50,318 mainnet blocks). Block-source classification uses `fct_block_mev`: any block delivered through a tracked relay is tagged as MEV-Boost; everything else is treated as locally-built.

<SqlSource source="xatu_cbt" query="bsp_headline" />

<DataTable data={headline} rows=2>
    <Column id="source" title="Source" />
    <Column id="blocks" title="Blocks" fmt="num0" />
    <Column id="p50_pre_kb"  title="p50 size pre-snappy (KB)"  fmt="num0" />
    <Column id="p50_post_kb" title="p50 size post-snappy (KB)" fmt="num0" />
    <Column id="p95_pre_kb"  title="p95 size pre-snappy (KB)"  fmt="num0" />
    <Column id="p50_gas_M"   title="p50 gas (M)"        fmt="num1" />
    <Column id="p50_t_first_ms" title="p50 t_first (ms)" fmt="num0" />
    <Column id="p95_t_first_ms" title="p95 t_first (ms)" fmt="num0" />
</DataTable>

MEV-Boost is 95% of the window. Locally-built blocks are smaller (70 vs 165 KB pre-snappy at the median) and use less gas (11M vs 30M).

</Section>

<Section type="investigation">

## Investigation

### When measured from slot start

For reference, here is the naive view: bin every individual-class node observation by post-snappy block size and plot the median, p95, and p99 of `seen_slot_start_diff`.

<SqlSource source="xatu_cbt" query="bsp_naive_view" />

<ECharts config={naiveConfig} height="400px" />

A 9 KB block reaches the median individual node at 1505 ms; a 238 KB block at 2122 ms. That works out to roughly **3.7 ms per post-snappy KB at p50**. The 4-second attestation deadline sits comfortably above the p99 line for every size on mainnet today. This is what people usually quote, but it includes builder release timing — see the methodology note in the background for why we move the origin to `t_first` for the rest of the investigation.

### When measured from first sighting

Subtract `t_first` per block from each individual-node observation. What remains is pure mesh dispersion.

<SqlSource source="xatu_cbt" query="bsp_pure_dispersion" />

<ECharts config={dispersionConfig} height="400px" />

The numbers are much smaller. Median dispersion ranges from 104 ms (9 KB) to 348 ms (~238 KB). p99 ranges from 427 ms to 1248 ms. The slope is about **0.9 ms per post-snappy KB at p50**, **2.5 ms/KB at p95**, **3.7 ms/KB at p99**.

Within any single bin the spread is large. Most of the propagation variance comes from per-pair network conditions like peering, geography and link latency, not from block size. The size effect is real and monotonic, but it sits on top of much larger noise from network topology.

### When comparing MEV-Boost to locally-built

A locally-built block enters the network through the proposer's own ~8-peer gossipsub mesh and starts spreading hop-by-hop from there. A MEV-Boost block is published by the relay, which is connected to a much larger set of CL nodes and could in principle blast it to many of them at once before gossipsub takes over. If relays are doing that, MEV-Boost blocks should disperse faster from `t_first` than local blocks at the same size, especially in the early percentiles.

<SqlSource source="xatu_cbt" query="bsp_dispersion_lookup" />

<ECharts config={bySourceConfig} height="400px" />

The two p50 lines sit on top of each other. The two p95 lines do too. At every size band, dispersion-from-first-sighting is indistinguishable between the two sources, so relays don't appear to be giving MEV-Boost blocks a head start over the proposer-mesh path that locally-built blocks take. Whatever the relay's peer set looks like, the network sees the same dispersion curve from `t_first` onwards either way.

#### Lookup tables for the simulator

Per-bin dispersion percentiles. Cell colour shades light to dark by latency. The two tables look essentially the same, which is the whole point: the gossipsub mesh treats MEV-Boost and locally-built blocks identically.

**MEV-Boost** (95% of mainnet)

<DataTable data={mev_rows} rows=15>
    <Column id="size_bin"   title="Post-snappy size" />
    <Column id="avg_pre_kb" title="≈ pre-snappy (KB)" fmt="num0" align="right" />
    <Column id="n"          title="n observations" fmt="num0" align="right" />
    <Column id="p50"        title="p50 (ms)" fmt="num0" contentType="colorscale" scaleColor="#3b82f6" />
    <Column id="p75"        title="p75 (ms)" fmt="num0" contentType="colorscale" scaleColor="#3b82f6" />
    <Column id="p95"        title="p95 (ms)" fmt="num0" contentType="colorscale" scaleColor="#3b82f6" />
    <Column id="p99"        title="p99 (ms)" fmt="num0" contentType="colorscale" scaleColor="#3b82f6" />
</DataTable>

**Local** (5% of mainnet)

<DataTable data={local_rows} rows=15>
    <Column id="size_bin"   title="Post-snappy size" />
    <Column id="avg_pre_kb" title="≈ pre-snappy (KB)" fmt="num0" align="right" />
    <Column id="n"          title="n observations" fmt="num0" align="right" />
    <Column id="p50"        title="p50 (ms)" fmt="num0" contentType="colorscale" scaleColor="#16a34a" />
    <Column id="p75"        title="p75 (ms)" fmt="num0" contentType="colorscale" scaleColor="#16a34a" />
    <Column id="p95"        title="p95 (ms)" fmt="num0" contentType="colorscale" scaleColor="#16a34a" />
    <Column id="p99"        title="p99 (ms)" fmt="num0" contentType="colorscale" scaleColor="#16a34a" />
</DataTable>

Compare any row across the two tables and the percentiles match within tens of milliseconds, well under the per-bin spread.

</Section>

<Section type="takeaways">

## Takeaways

- Pure gossip mesh dispersion is small at today's block sizes. p50 fits `132 + 0.93 * post_snappy_KB` ms; p99 fits `655 + 3.66 * post_snappy_KB` ms. A typical 73 KB block at p50 disperses in around **200 ms**; a p99-sized 184 KB block at p99 disperses in around **1330 ms**.
- For a simulator that wants to model "how fast does a payload of size X disseminate across mainnet today," use the dispersion lookup table directly.
- MEV-Boost relays don't appear to give their blocks a wider initial broadcast than the proposer-mesh path that locally-built blocks take. Once a block is on the network, MEV and local disperse at the same rate at every size band.
- The 4-second attestation deadline is not at risk for any size band currently on mainnet. p99 of mesh dispersion stays under 1.3 seconds after first network sighting for the largest size bin observed (224+ KB post-snappy).

</Section>
