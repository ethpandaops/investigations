---
title: identity
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: callersConfig = (() => {
        if (!identity_callers || identity_callers.length === 0 || identity_callers[0].calling_contract == null) return {};
        const sorted = [...identity_callers].sort((a, b) => Number(a.total_calls) - Number(b.total_calls));
        const truncate = (addr) => addr.slice(0, 10) + '...' + addr.slice(-4);
        return {
            title: { text: 'Top Contracts Calling identity', left: 'center', textStyle: { fontSize: 13 } },
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
                itemStyle: { color: '#16a34a' },
                barMaxWidth: 30,
                label: { show: true, position: 'right', fontSize: 9, formatter: p => Number(p.value).toLocaleString() }
            }]
        };
    })();

    $: gasDistConfig = (() => {
        if (!identity_gas_dist || identity_gas_dist.length === 0 || identity_gas_dist[0].gas_value == null) return {};
        return {
            title: { text: 'identity Gas Value Distribution', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                formatter: (params) => {
                    const d = params[0];
                    const row = identity_gas_dist.find(r => String(r.gas_value) === d.name);
                    return `Gas: ${d.name}<br/>Calls: ${Number(d.value).toLocaleString()} (${row?.pct}%)`;
                }
            },
            grid: { left: 10, right: 15, bottom: 70, top: 50, containLabel: true },
            xAxis: {
                type: 'category',
                data: identity_gas_dist.map(d => String(d.gas_value)),
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
                data: identity_gas_dist.map(d => Number(d.call_count)),
                itemStyle: { color: '#16a34a' },
                barMaxWidth: 60
            }]
        };
    })();
</script>

<PageMeta
    date="2026-03-12T00:00:00Z"
    authors={["samcm", "mattevans"]}
    tags={["precompiles", "execution", "identity"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-29T00:00:00Z"
    endTime="2026-02-26T23:59:59Z"
/>

```sql identity_callers
select * from xatu_cbt.precompile_identity_callers
```

```sql identity_gas_dist
select * from xatu_cbt.precompile_identity_gas_dist
```

<Section type="question">

## Question

Who uses the identity precompile and what data sizes are being copied?

</Section>

<Section type="background">

## Background

**identity** (`0x04`) just returns its input data unchanged. It exists as a cheap way to copy data in memory. Gas cost: 15 base + 3 per 32-byte word.

With 14.6 million calls, identity is #3 by call count. But at an average of just 27 gas per call, it's only 0.2% of precompile gas. Most calls copy very small amounts of data.

</Section>

<Section type="investigation">

## Investigation

### Gas distribution

Since gas scales with input size, the distribution shows how much data is being copied per call.

<SqlSource source="xatu_cbt" query="precompile_identity_gas_dist" />

<ECharts config={gasDistConfig} height="400px" />

### Top callers

> **Note:** The callers data below covers a smaller window (~6,000 blocks) because the self-join query needed to resolve parent contracts is too expensive to run over the full range. The gas distribution above uses the full 426K-block range.

<SqlSource source="xatu_cbt" query="precompile_identity_callers" />

<ECharts config={callersConfig} height="400px" />

</Section>

<Section type="takeaways">

## Takeaways

- identity is #3 by call count (14.6M) but negligible gas (0.2% of total)
- Average 27 gas per call means most copies are tiny (1 word or less)

</Section>
