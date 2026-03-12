---
title: blake2f
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: callersConfig = (() => {
        if (!blake2f_callers || blake2f_callers.length === 0 || blake2f_callers[0].calling_contract == null) return {};
        const sorted = [...blake2f_callers].sort((a, b) => Number(a.blake2f_calls) - Number(b.blake2f_calls));
        const truncate = (addr) => addr.slice(0, 10) + '...' + addr.slice(-4);
        return {
            title: { text: 'Top Contracts Calling blake2f', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = sorted.find(r => truncate(r.calling_contract) === d.name);
                    return `<b>${row?.calling_contract}</b><br/>Calls: ${Number(d.value).toLocaleString()}<br/>Avg gas: ${Number(row?.avg_gas).toLocaleString()}`;
                }
            },
            grid: { left: 10, right: 30, bottom: 50, top: 50, containLabel: true },
            xAxis: {
                type: 'value',
                name: 'Calls',
                nameLocation: 'center',
                nameGap: 30,
                axisLabel: { formatter: v => v >= 1e3 ? (v / 1e3).toFixed(0) + 'K' : v }
            },
            yAxis: {
                type: 'category',
                data: sorted.map(d => truncate(d.calling_contract)),
                axisLabel: { fontSize: 9, fontFamily: 'monospace' }
            },
            series: [{
                type: 'bar',
                data: sorted.map(d => Number(d.blake2f_calls)),
                itemStyle: { color: '#7c3aed' },
                barMaxWidth: 30,
                label: { show: true, position: 'right', fontSize: 9, formatter: p => Number(p.value).toLocaleString() }
            }]
        };
    })();

    $: gasDistConfig = (() => {
        if (!blake2f_gas_dist || blake2f_gas_dist.length === 0 || blake2f_gas_dist[0].gas_value == null) return {};
        return {
            title: { text: 'blake2f Gas Value Distribution', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = blake2f_gas_dist.find(r => String(r.gas_value) === d.name);
                    return `Gas: ${d.name}<br/>Calls: ${Number(d.value).toLocaleString()} (${row?.pct}%)`;
                }
            },
            grid: { left: 10, right: 15, bottom: 70, top: 50, containLabel: true },
            xAxis: {
                type: 'category',
                data: blake2f_gas_dist.map(d => String(d.gas_value)),
                axisLabel: { rotate: 45, fontSize: 10 },
                name: 'Gas Value',
                nameLocation: 'center',
                nameGap: 50
            },
            yAxis: {
                type: 'value',
                name: 'Call Count',
                nameLocation: 'center',
                nameGap: 50,
                nameRotate: 90,
                axisLabel: { formatter: v => v >= 1e6 ? (v / 1e6).toFixed(1) + 'M' : v >= 1e3 ? (v / 1e3).toFixed(0) + 'K' : v }
            },
            series: [{
                type: 'bar',
                data: blake2f_gas_dist.map(d => Number(d.call_count)),
                itemStyle: { color: '#7c3aed' },
                barMaxWidth: 60
            }]
        };
    })();
</script>

<PageMeta
    date="2026-03-12T00:00:00Z"
    authors={["samcm", "mattevans"]}
    tags={["precompiles", "execution", "blake2f"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-29T00:00:00Z"
    endTime="2026-02-26T23:59:59Z"
/>

```sql blake2f_callers
select * from xatu_cbt.precompile_blake2f_callers
```

```sql blake2f_gas_dist
select * from xatu_cbt.precompile_blake2f_gas_dist
```

<Section type="question">

## Question

Who uses blake2f and how much computation are they requesting per call?

</Section>

<Section type="background">

## Background

**blake2f** (`0x09`) runs the BLAKE2b compression function F. It was added in EIP-152 to support Zcash's Equihash verification on Ethereum. Gas cost scales with the number of rounds requested.

With only 3,362 calls over the analysis period, blake2f is the second least-used precompile. A handful of contracts drive all the usage.

</Section>

<Section type="investigation">

## Investigation

### Gas distribution

Gas scales with the number of BLAKE2b rounds. The distribution shows what round counts callers are requesting.

<SqlSource source="xatu_cbt" query="precompile_blake2f_gas_dist" />

<ECharts config={gasDistConfig} height="400px" />

### Top callers

> **Note:** The callers data below covers a smaller window (~6,000 blocks) because the self-join query needed to resolve parent contracts is too expensive to run over the full range. The gas distribution above uses the full 426K-block range.

<SqlSource source="xatu_cbt" query="precompile_blake2f_callers" />

<ECharts config={callersConfig} height="400px" />

</Section>

<Section type="takeaways">

## Takeaways

- blake2f is barely used: 3,362 calls over ~426K blocks
- Usage is concentrated in a handful of contracts

</Section>
