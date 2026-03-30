---
title: Node CPU Resource Usage
sidebar_position: 1
description: How much CPU do consensus and execution clients consume on Ethereum mainnet full nodes
date: 2026-03-30T00:00:00Z
author: samcm
tags:
  - resources
  - cpu
  - consensus-layer
  - execution-layer
  - observoor
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    // --- Chart: Summary bar chart ---
    $: summaryConfig = (() => {
        if (!cl_summary || cl_summary.length === 0 || cl_summary[0].client_type == null) return {};
        const data = [...cl_summary].sort((a, b) => Number(a.avg_cores) - Number(b.avg_cores));
        const colors = { nimbus: '#4363d8', lodestar: '#ffe119', prysm: '#3cb44b', lighthouse: '#9933ff' };
        return {
            title: { text: 'Average CL CPU Usage (cores)', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis', formatter: (params) => {
                const name = params[0].name;
                const row = data.find(d => d.client_type === name);
                return `<b>${name}</b><br/>avg: ${row.avg_cores} cores<br/>p95: ${row.p95_cores}<br/>peak: ${row.peak_cores}`;
            }},
            grid: { left: 10, right: 30, bottom: 30, top: 50, containLabel: true },
            xAxis: { type: 'category', data: data.map(d => d.client_type), axisLabel: { fontSize: 12 } },
            yAxis: { type: 'value', name: 'CPU Cores', nameLocation: 'center', nameGap: 40, nameRotate: 90 },
            series: [{
                type: 'bar',
                data: data.map(d => ({ value: Number(d.avg_cores), itemStyle: { color: colors[d.client_type] } })),
                barMaxWidth: 50,
                label: { show: true, position: 'top', formatter: '{c}', fontSize: 11 }
            }]
        };
    })();

    // --- Chart: Hourly CPU time series ---
    $: hourlyConfig = (() => {
        if (!cl_hourly || cl_hourly.length === 0 || cl_hourly[0].hour == null) return {};

        const clients = [...new Set(cl_hourly.map(d => d.client_type))];
        const hours = [...new Set(cl_hourly.map(d => d.hour))];
        const colors = { nimbus: '#4363d8', lodestar: '#ffe119', prysm: '#3cb44b', lighthouse: '#9933ff' };

        const dataMap = {};
        cl_hourly.forEach(d => {
            if (!dataMap[d.client_type]) dataMap[d.client_type] = {};
            dataMap[d.client_type][d.hour] = Number(d.avg_cores);
        });

        return {
            title: { text: 'CL Client CPU Over Time (Hourly Average)', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis', formatter: (params) => {
                let s = `<b>${params[0].axisValue}</b><br/>`;
                params.forEach(p => { s += `${p.marker} ${p.seriesName}: ${Number(p.value).toFixed(2)} cores<br/>`; });
                return s;
            }},
            grid: { left: 60, right: 130, bottom: 80, top: 50 },
            xAxis: {
                type: 'category',
                data: hours,
                axisLabel: { interval: 23, rotate: 45, fontSize: 9, formatter: (v) => v.substring(5, 16) },
                name: 'Time (UTC)',
                nameLocation: 'center',
                nameGap: 60
            },
            yAxis: { type: 'value', name: 'CPU Cores', nameLocation: 'center', nameGap: 40, nameRotate: 90 },
            legend: { data: clients, right: 10, orient: 'vertical', top: 'center' },
            series: clients.map(c => ({
                name: c,
                type: 'line',
                data: hours.map(h => dataMap[c]?.[h] || 0),
                itemStyle: { color: colors[c] },
                lineStyle: { color: colors[c], width: 1.5 },
                symbol: 'none'
            }))
        };
    })();

    // --- Chart: CPU by slot position in epoch ---
    $: epochSlotConfig = (() => {
        if (!cl_by_epoch_slot || cl_by_epoch_slot.length === 0 || cl_by_epoch_slot[0].slot_in_epoch == null) return {};

        const clients = [...new Set(cl_by_epoch_slot.map(d => d.client_type))];
        const slots = [...new Set(cl_by_epoch_slot.map(d => Number(d.slot_in_epoch)))].sort((a, b) => a - b);
        const colors = { nimbus: '#4363d8', lodestar: '#ffe119', prysm: '#3cb44b', lighthouse: '#9933ff' };

        const dataMap = {};
        cl_by_epoch_slot.forEach(d => {
            if (!dataMap[d.client_type]) dataMap[d.client_type] = {};
            dataMap[d.client_type][Number(d.slot_in_epoch)] = Number(d.avg_cores);
        });

        return {
            title: { text: 'CL CPU by Slot Position Within Epoch', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis' },
            grid: { left: 60, right: 130, bottom: 60, top: 50 },
            xAxis: {
                type: 'category',
                data: slots,
                name: 'Slot in Epoch (0 = first, 31 = last)',
                nameLocation: 'center',
                nameGap: 35
            },
            yAxis: { type: 'value', name: 'CPU Cores', nameLocation: 'center', nameGap: 40, nameRotate: 90 },
            legend: { data: clients, right: 10, orient: 'vertical', top: 'center' },
            series: clients.map(c => ({
                name: c,
                type: 'line',
                data: slots.map(s => dataMap[c]?.[s] || 0),
                itemStyle: { color: colors[c] },
                lineStyle: { color: colors[c], width: 2 },
                symbol: 'none'
            }))
        };
    })();

    // --- Charts: Intra-slot CPU per CL+EL pair ---
    $: intraSlotConfigs = (() => {
        if (!cl_intra_slot || cl_intra_slot.length === 0 || cl_intra_slot[0].window_in_slot == null) return {};

        const clients = ['nimbus', 'lodestar', 'prysm', 'lighthouse'];
        const elPairs = { lighthouse: 'Geth', prysm: 'Geth', lodestar: 'Nethermind', nimbus: 'Besu' };
        const elNodes = {
            lighthouse: 'utility-mainnet-lighthouse-geth-001',
            prysm: 'utility-mainnet-prysm-geth-tysm-001'
        };

        const windows = Array.from({ length: 60 }, (_, i) => i);
        const seconds = windows.map(w => (w * 0.2).toFixed(1));

        // Build EL lookup: node+position+window -> cores
        const elMap = {};
        if (el_intra_slot && el_intra_slot.length > 0 && el_intra_slot[0].window_in_slot != null) {
            el_intra_slot.forEach(d => {
                const key = `${d.meta_client_name}_${d.epoch_position}_${Number(d.window_in_slot)}`;
                elMap[key] = Number(d.avg_cores);
            });
        }

        const configs = {};
        clients.forEach(client => {
            const clientData = cl_intra_slot.filter(d => d.client_type === client);
            const hasElData = !!elNodes[client];
            const elNode = elNodes[client];

            const clMap = {};
            clientData.forEach(d => {
                clMap[`${d.epoch_position}_${Number(d.window_in_slot)}`] = Number(d.avg_cores);
            });

            const series = [
                { name: `${client} (mid-epoch)`, type: 'line', data: windows.map(w => clMap[`mid_epoch_${w}`] || 0), itemStyle: { color: '#94a3b8' }, lineStyle: { color: '#94a3b8', width: 1 }, symbol: 'none' },
                { name: `${client} (epoch boundary)`, type: 'line', data: windows.map(w => clMap[`epoch_end_${w}`] || 0), itemStyle: { color: '#2563eb' }, lineStyle: { color: '#2563eb', width: 2 }, areaStyle: { opacity: 0.08 }, symbol: 'none' }
            ];

            if (hasElData) {
                series.push(
                    { name: `${elPairs[client].toLowerCase()} (mid-epoch)`, type: 'line', data: windows.map(w => elMap[`${elNode}_mid_epoch_${w}`] || 0), itemStyle: { color: '#d4d4d4' }, lineStyle: { color: '#d4d4d4', width: 1, type: 'dashed' }, symbol: 'none' },
                    { name: `${elPairs[client].toLowerCase()} (epoch boundary)`, type: 'line', data: windows.map(w => elMap[`${elNode}_epoch_end_${w}`] || 0), itemStyle: { color: '#f97316' }, lineStyle: { color: '#f97316', width: 2, type: 'dashed' }, areaStyle: { opacity: 0.05 }, symbol: 'none' }
                );
            }

            const legendData = series.map(s => s.name);
            const elNote = hasElData ? '' : ` (${elPairs[client]} EL data unavailable — observoor bug)`;

            configs[client] = {
                title: { text: `${client.charAt(0).toUpperCase() + client.slice(1)} + ${elPairs[client]}${elNote}`, left: 'center', textStyle: { fontSize: 13 } },
                tooltip: { trigger: 'axis', formatter: (params) => {
                    let s = `<b>${params[0].axisValue}s into slot</b><br/>`;
                    params.forEach(p => { if (Number(p.value) > 0) s += `${p.marker} ${p.seriesName}: ${Number(p.value).toFixed(2)} cores<br/>`; });
                    return s;
                }},
                grid: { left: 60, right: 200, bottom: 60, top: 50 },
                xAxis: { type: 'category', data: seconds, axisLabel: { interval: 9, fontSize: 10 }, name: 'Seconds into Slot', nameLocation: 'center', nameGap: 35 },
                yAxis: { type: 'value', name: 'CPU Cores', nameLocation: 'center', nameGap: 40, nameRotate: 90 },
                legend: { data: legendData, right: 10, orient: 'vertical', top: 'center', textStyle: { fontSize: 9 } },
                series: series
            };
        });
        return configs;
    })();

    // --- Chart: EIP-7870 reference nodes ---
    $: ref7870Config = (() => {
        if (!ref_7870 || ref_7870.length === 0 || ref_7870[0].el_client == null) return {};
        const data = [...ref_7870].sort((a, b) => Number(b.total_avg_cores) - Number(a.total_avg_cores));
        const elClients = data.map(d => d.el_client);
        const elColors = { geth: '#2563eb', besu: '#9333ea', nethermind: '#16a34a', reth: '#dc2626', ethrex: '#f59e0b', erigon: '#64748b' };

        return {
            title: { text: 'EIP-7870 Reference Nodes: CL + EL CPU (All Prysm CL)', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis', formatter: (params) => {
                let s = `<b>Prysm + ${params[0].name}</b><br/>`;
                params.forEach(p => { s += `${p.marker} ${p.seriesName}: ${Number(p.value).toFixed(2)} cores<br/>`; });
                const row = data.find(d => d.el_client === params[0].name);
                if (row) s += `<b>Total: ${Number(row.total_avg_cores).toFixed(2)} cores</b>`;
                return s;
            }},
            grid: { left: 60, right: 30, bottom: 50, top: 50 },
            xAxis: { type: 'category', data: elClients, axisLabel: { fontSize: 11 } },
            yAxis: { type: 'value', name: 'CPU Cores (24h avg)', nameLocation: 'center', nameGap: 40, nameRotate: 90 },
            legend: { data: ['Prysm (CL)', 'EL Client'], top: 'bottom' },
            series: [
                {
                    name: 'Prysm (CL)',
                    type: 'bar',
                    stack: 'total',
                    data: data.map(d => Number(d.cl_avg_cores)),
                    itemStyle: { color: '#3cb44b' },
                    barMaxWidth: 50
                },
                {
                    name: 'EL Client',
                    type: 'bar',
                    stack: 'total',
                    data: data.map(d => ({ value: Number(d.el_avg_cores), itemStyle: { color: elColors[d.el_client] || '#888' } })),
                    barMaxWidth: 50
                }
            ]
        };
    })();
</script>

<PageMeta
    date="2026-03-30T00:00:00Z"
    author="samcm"
    tags={["resources", "cpu", "consensus-layer", "execution-layer", "observoor"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-03-10T00:00:00Z"
    endTime="2026-03-16T23:59:59Z"
/>

```sql cl_summary
select * from xatu.node_cpu_cl_summary
```

```sql cl_hourly
select * from xatu.node_cpu_cl_hourly
```

```sql cl_by_epoch_slot
select * from xatu.node_cpu_cl_by_epoch_slot
```

```sql cl_intra_slot
select * from xatu.node_cpu_cl_intra_slot
```

```sql el_summary
select * from xatu.node_cpu_el_summary
```

```sql el_intra_slot
select * from xatu.node_cpu_el_intra_slot
```

```sql ref_7870
select * from xatu.node_cpu_7870_summary
```

<Section type="question">

## Question

How much CPU do consensus and execution layer clients use on Ethereum mainnet full nodes? Can we isolate non-execution overhead from total process CPU?

</Section>

<Section type="background">

## Background

Researchers want to know how many CPU cores are typically occupied by non-execution tasks on a full Ethereum node: attestation processing, state management, p2p networking, epoch transitions, and so on. This matters for realistic benchmarking of block execution, where you need to know how much CPU budget is left over after the CL and EL background work.

We measure process-level CPU using **observoor**, an eBPF-based profiler running on our Xatu nodes at 200ms intervals, giving sub-slot resolution within Ethereum's 12-second slots. The `total_on_cpu_ns` metric was cross-validated against Prometheus `container_cpu_usage_seconds_total`. It is accurate for Lighthouse, Prysm, Lodestar, Nimbus, and Geth. Grandine, Teku, Besu, Nethermind, and Reth showed inflated values (2x to 7500x) due to an eBPF profiling issue with certain runtimes and are excluded.

**Important caveat:** These are process-level metrics. CL CPU is entirely non-execution work (attestations, state transitions, p2p). But EL CPU is a mix of block execution, mempool management, p2p networking, and state trie maintenance. We can't separate "pure execution" from "EL background work" at this level of instrumentation.

</Section>

<Section type="investigation">

## Investigation

### Nodes Analyzed

One representative node per CL client, all 32-core machines, non-proposing. These are busy infrastructure nodes that also serve API calls and run debugging tools, so CPU figures here are an upper bound.

| CL Client | EL Client | Node |
|-----------|-----------|------|
| Lighthouse | Geth | `utility-mainnet-lighthouse-geth-001` |
| Prysm | Geth | `utility-mainnet-prysm-geth-tysm-001` |
| Lodestar | Nethermind | `utility-mainnet-lodestar-nethermind-001` |
| Nimbus | Besu | `utility-mainnet-nimbus-besu-001` |

For EL baseline, the Geth instance on `utility-mainnet-lighthouse-geth-001` is used.

### Overall CL CPU Usage

<SqlSource source="xatu" query="node_cpu_cl_summary" />

<ECharts config={summaryConfig} height="400px" />

<DataTable data={cl_summary} rows=4>
    <Column id="client_type" title="CL Client" />
    <Column id="avg_cores" title="Avg Cores" fmt="num2" />
    <Column id="p50_cores" title="p50 Cores" fmt="num2" />
    <Column id="p95_cores" title="p95 Cores" fmt="num2" />
    <Column id="p99_cores" title="p99 Cores" fmt="num2" />
    <Column id="peak_cores" title="Peak Cores" fmt="num2" />
</DataTable>

Lighthouse is the most CPU-hungry CL client at ~5.6 cores on average, followed by Prysm at ~1.9 cores. Lodestar and Nimbus are both under 1 core.

### Over Time

<SqlSource source="xatu" query="node_cpu_cl_hourly" />

<ECharts config={hourlyConfig} height="450px" />

CPU usage is stable across the week. Lighthouse has the most variance, with periodic spikes likely from epoch processing.

### When Processing Epoch Transitions

An epoch on Ethereum is 32 slots (~6.4 minutes). At epoch boundaries the CL client must process the **epoch state transition** — computing rewards, shuffling committees, and updating validator balances. This is the heaviest CL workload.

<SqlSource source="xatu" query="node_cpu_cl_by_epoch_slot" />

<ECharts config={epochSlotConfig} height="400px" />

Slot 0 (first slot of new epoch) and slot 31 (last slot, where state transition begins) show elevated CPU for all clients. Lighthouse is the most visible, jumping from ~5.6 to ~6.2 cores at epoch boundaries.

### Within a Single Slot

Each slot is 12 seconds. With 200ms sampling, we can see what happens *inside* a slot. These charts show both CL and EL CPU, comparing mid-epoch slots against epoch boundary slots. EL data (dashed lines) is only available for Geth; Besu and Nethermind have broken observoor data.

<SqlSource source="xatu" query="node_cpu_cl_intra_slot" />
<SqlSource source="xatu" query="node_cpu_el_intra_slot" />

{#if intraSlotConfigs?.lighthouse}
<ECharts config={intraSlotConfigs.lighthouse} height="350px" />
{/if}

{#if intraSlotConfigs?.prysm}
<ECharts config={intraSlotConfigs.prysm} height="350px" />
{/if}

{#if intraSlotConfigs?.lodestar}
<ECharts config={intraSlotConfigs.lodestar} height="350px" />
{/if}

{#if intraSlotConfigs?.nimbus}
<ECharts config={intraSlotConfigs.nimbus} height="350px" />
{/if}

Epoch boundary work concentrates in the second half of the slot (6-12s). Lighthouse spikes from ~5 cores to ~14 at epoch boundaries. Lodestar goes from under 1 core to nearly 8, the biggest relative jump. Prysm peaks around 5 cores. Nimbus stays flat at under 1 core throughout.

### EL Client Baseline

The EL client also uses CPU for mempool management, p2p, and state trie maintenance even when not producing blocks. Only Geth is shown here since other EL clients had unreliable observoor data.

<SqlSource source="xatu" query="node_cpu_el_summary" />

<DataTable data={el_summary} rows=4>
    <Column id="client_type" title="EL Client" />
    <Column id="meta_client_name" title="Node" />
    <Column id="avg_cores" title="Avg Cores" fmt="num2" />
    <Column id="p50_cores" title="p50 Cores" fmt="num2" />
    <Column id="p95_cores" title="p95 Cores" fmt="num2" />
    <Column id="peak_cores" title="Peak Cores" fmt="num2" />
</DataTable>

Geth uses under 1 core on average when idle.

### EIP-7870 Reference Nodes

The EIP-7870 reference nodes all run Prysm as the CL, each paired with a different EL client. They run on 16-core (ax52) and 20-core (asus-sydney) machines with minimal additional workload, so these numbers are a lower bound.

Data source: Prometheus `container_cpu_usage_seconds_total` (24h, 1m resolution, 2m rate).

<SqlSource source="xatu" query="node_cpu_7870_summary" />

<ECharts config={ref7870Config} height="400px" />

<DataTable data={ref_7870} rows=6>
    <Column id="el_client" title="EL Client" />
    <Column id="cl_avg_cores" title="CL Avg" fmt="num2" />
    <Column id="cl_p95_cores" title="CL p95" fmt="num2" />
    <Column id="el_avg_cores" title="EL Avg" fmt="num2" />
    <Column id="el_p95_cores" title="EL p95" fmt="num2" />
    <Column id="total_avg_cores" title="Total Avg" fmt="num2" />
</DataTable>

With the same CL across all pairs, total non-execution overhead is 0.6 to 1.1 cores on average. EL client choice matters less than CL choice: EL idle CPU ranges from 0.15 (Erigon) to 0.48 cores (Reth). Prysm's CL overhead is consistent at 0.5-0.9 cores regardless of which EL it's paired with.

</Section>

<Section type="takeaways">

## Takeaways

- On the EIP-7870 reference nodes (Prysm + 6 different EL clients, 16/20-core machines), total CL + EL process CPU is **0.6-1.1 cores**. This is the best lower bound we have for total node overhead
- CL CPU varies a lot by client. On busy infrastructure nodes: Nimbus and Lodestar `< 1 core`, Prysm ~2 cores, Lighthouse ~5.6 cores. At epoch boundaries these spike to 5-14 cores briefly (second half of the slot)
- EL process CPU includes both execution and background work (mempool, p2p, state trie) and we can't split these apart with process-level metrics. Properly isolating non-execution EL overhead would need function-level profiling

</Section>
