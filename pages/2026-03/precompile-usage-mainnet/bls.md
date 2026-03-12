---
title: BLS12-381 operations
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: gasDistConfig = (() => {
        if (!bls12_gas_dist || bls12_gas_dist.length === 0 || bls12_gas_dist[0].gas_value == null) return {};
        const precompiles = [...new Set(bls12_gas_dist.map(d => d.precompile))];
        const colors = {
            'g1add': '#059669', 'g1mul': '#0d9488', 'g1multiexp': '#0891b2',
            'g2add': '#4f46e5', 'g2mul': '#7c3aed', 'g2multiexp': '#a855f7',
            'pairing': '#db2777', 'map_fp_to_g1': '#e11d48', 'map_fp2_to_g2': '#f43f5e'
        };

        const allGasValues = [...new Set(bls12_gas_dist.map(d => String(d.gas_value)))];
        const dataMap = {};
        bls12_gas_dist.forEach(d => {
            if (!dataMap[d.precompile]) dataMap[d.precompile] = {};
            dataMap[d.precompile][String(d.gas_value)] = Number(d.call_count);
        });

        return {
            title: { text: 'BLS12-381 Gas Value Distribution by Operation', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: { trigger: 'axis' },
            legend: { data: precompiles, top: 28 },
            grid: { left: 10, right: 15, bottom: 70, top: 60, containLabel: true },
            xAxis: {
                type: 'category',
                data: allGasValues,
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
            series: precompiles.map(p => ({
                name: p,
                type: 'bar',
                data: allGasValues.map(g => dataMap[p]?.[g] || 0),
                itemStyle: { color: colors[p] || '#999' },
                barMaxWidth: 40
            }))
        };
    })();
</script>

<PageMeta
    date="2026-03-12T00:00:00Z"
    authors={["samcm", "mattevans"]}
    tags={["precompiles", "execution", "bls12-381", "pectra"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-29T00:00:00Z"
    endTime="2026-02-26T23:59:59Z"
/>

```sql bls12_gas_dist
select * from xatu_cbt.precompile_bls12_gas_dist
```

<Section type="question">

## Question

How are the new BLS12-381 precompiles being used since Pectra went live?

</Section>

<Section type="background">

## Background

EIP-2537 added nine BLS12-381 precompiles at addresses `0x0b` through `0x13`, activated with the Pectra hard fork. These enable native BLS signature verification and other pairing-based cryptography on the BLS12-381 curve (the curve used by Ethereum's consensus layer).

| Address | Name | Function |
|---------|------|----------|
| `0x0b` | g1add | G1 point addition |
| `0x0c` | g1mul | G1 scalar multiplication |
| `0x0d` | g1multiexp | G1 multi-scalar multiplication |
| `0x0e` | g2add | G2 point addition |
| `0x0f` | g2mul | G2 scalar multiplication |
| `0x10` | g2multiexp | G2 multi-scalar multiplication |
| `0x11` | pairing | BLS12-381 pairing check |
| `0x12` | map\_fp\_to\_g1 | Map field element to G1 |
| `0x13` | map\_fp2\_to\_g2 | Map field element to G2 |

Despite Pectra being live for the entire analysis window, BLS12-381 usage is extremely sparse — only 63 calls total.

</Section>

<Section type="investigation">

## Investigation

### Gas distribution

Gas costs vary by operation type and input size.

<SqlSource source="xatu_cbt" query="precompile_bls12_gas_dist" />

<ECharts config={gasDistConfig} height="400px" />

No callers chart for BLS12-381. The self-join query needed for caller resolution uses a reduced ~6,000 block window, and that window contained zero BLS12-381 calls. All 63 calls landed in blocks 24,393,600 to 24,422,400, well before the callers sample window.

</Section>

<Section type="takeaways">

## Takeaways

- Only 63 BLS12-381 calls total across the entire 426K-block analysis window, all concentrated in blocks 24,393,600 to 24,422,400
- g2multiexp accounts for 48 of those 63 calls, consuming 292M gas
- g1mul, pairing, g1multiexp, g2mul, and g2add have single-digit usage each
- g1add, map\_fp\_to\_g1, and map\_fp2\_to\_g2 have zero calls in this window

</Section>
