---
title: ecrecover
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: callersConfig = (() => {
        if (!ecrecover_callers || ecrecover_callers.length === 0 || ecrecover_callers[0].calling_contract == null) return {};
        const sorted = [...ecrecover_callers].sort((a, b) => Number(a.total_calls) - Number(b.total_calls));
        const truncate = (addr) => addr.slice(0, 10) + '...' + addr.slice(-4);
        return {
            title: { text: 'Top Contracts Calling ecrecover', left: 'center', textStyle: { fontSize: 13 } },
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
                axisLabel: { formatter: v => v >= 1e6 ? (v / 1e6).toFixed(1) + 'M' : v >= 1e3 ? (v / 1e3).toFixed(0) + 'K' : v }
            },
            yAxis: {
                type: 'category',
                data: sorted.map(d => truncate(d.calling_contract)),
                axisLabel: { fontSize: 9, fontFamily: 'monospace' }
            },
            series: [{
                type: 'bar',
                data: sorted.map(d => Number(d.total_calls)),
                itemStyle: { color: '#2563eb' },
                barMaxWidth: 30,
                label: { show: true, position: 'right', fontSize: 9, formatter: p => Number(p.value).toLocaleString() }
            }]
        };
    })();

    $: gasDistConfig = (() => {
        if (!ecrecover_gas_dist || ecrecover_gas_dist.length === 0 || ecrecover_gas_dist[0].gas_value == null) return {};
        return {
            title: { text: 'ecrecover Gas Value Distribution', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = ecrecover_gas_dist.find(r => String(r.gas_value) === d.name);
                    return `Gas: ${d.name}<br/>Calls: ${Number(d.value).toLocaleString()} (${row?.pct}%)`;
                }
            },
            grid: { left: 10, right: 15, bottom: 70, top: 50, containLabel: true },
            xAxis: {
                type: 'category',
                data: ecrecover_gas_dist.map(d => String(d.gas_value)),
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
                data: ecrecover_gas_dist.map(d => Number(d.call_count)),
                itemStyle: { color: '#2563eb' },
                barMaxWidth: 60
            }]
        };
    })();
</script>

<PageMeta
    date="2026-03-12T00:00:00Z"
    authors={["samcm", "mattevans"]}
    tags={["precompiles", "execution", "ecrecover"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-29T00:00:00Z"
    endTime="2026-02-26T23:59:59Z"
/>

```sql ecrecover_callers
select * from xatu_cbt.precompile_ecrecover_callers
```

```sql ecrecover_gas_dist
select * from xatu_cbt.precompile_ecrecover_gas_dist
```

<Section type="question">

## Question

Who are the top consumers of ecrecover on mainnet?

</Section>

<Section type="background">

## Background

**ecrecover** (`0x01`) recovers the signer's public key from an ECDSA signature. Any contract that verifies a signature on-chain calls this. Fixed gas cost of 3,000.

Over the analysis period, ecrecover was called 15.9 million times, consuming 47.6 billion gas (25.2% of all precompile gas). It's the #2 precompile by both call count and gas.

</Section>

<Section type="investigation">

## Investigation

### Gas distribution

ecrecover has a fixed gas cost, so all calls should use 3,000 gas. The chart confirms whether that holds.

<SqlSource source="xatu_cbt" query="precompile_ecrecover_gas_dist" />

<ECharts config={gasDistConfig} height="400px" />

### Top callers

> **Note:** The callers data below covers a smaller window (~6,000 blocks) because the self-join query needed to resolve parent contracts is too expensive to run over the full range. The gas distribution above uses the full 426K-block range.

<SqlSource source="xatu_cbt" query="precompile_ecrecover_callers" />

<ECharts config={callersConfig} height="400px" />

</Section>

<Section type="takeaways">

## Takeaways

- ecrecover is #2 with 15.9M calls and 47.6B gas over the analysis period
- Fixed cost of 3,000 gas per call

</Section>
