---
title: point_evaluation
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    $: callersConfig = (() => {
        if (!point_eval_callers || point_eval_callers.length === 0 || point_eval_callers[0].calling_contract == null) return {};
        const sorted = [...point_eval_callers].sort((a, b) => Number(a.point_eval_calls) - Number(b.point_eval_calls));
        const truncate = (addr) => addr.slice(0, 10) + '...' + addr.slice(-4);
        return {
            title: { text: 'Top Contracts Calling point_evaluation', left: 'center', textStyle: { fontSize: 13 } },
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
                data: sorted.map(d => Number(d.point_eval_calls)),
                itemStyle: { color: '#0891b2' },
                barMaxWidth: 30,
                label: { show: true, position: 'right', fontSize: 9, formatter: p => Number(p.value).toLocaleString() }
            }]
        };
    })();
</script>

<PageMeta
    date="2026-03-12T00:00:00Z"
    authors={["samcm", "mattevans"]}
    tags={["precompiles", "execution", "point-evaluation", "blobs"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-29T00:00:00Z"
    endTime="2026-02-26T23:59:59Z"
/>

```sql point_eval_callers
select * from xatu_cbt.precompile_point_eval_callers
```

<Section type="question">

## Question

Who uses the point_evaluation precompile and what does the caller distribution look like?

</Section>

<Section type="background">

## Background

**point_evaluation** (`0x0a`) was introduced with EIP-4844 (Proto-Danksharding) in the Dencun upgrade. It verifies KZG proofs against blob commitments — the mechanism the protocol uses to confirm blob data integrity.

Every blob transaction that gets verified on-chain calls this precompile. Fixed gas cost of 50,000. Over the analysis period it was called 478K times, accounting for 12.7% of all precompile gas — #3 by gas despite ranking only #6 by call count.

</Section>

<Section type="investigation">

## Investigation

### Top callers

Every blob needs a KZG proof check, so the callers here are the contracts submitting blob transactions — mostly L2 sequencers and DA protocols.

> **Note:** The callers data below covers a smaller window (~6,000 blocks) because the self-join query needed to resolve parent contracts is too expensive to run over the full range.

<SqlSource source="xatu_cbt" query="precompile_point_eval_callers" />

<ECharts config={callersConfig} height="400px" />

No gas distribution chart here since point_evaluation has a fixed cost of 50,000 gas per call.

</Section>

<Section type="takeaways">

## Takeaways

- point_evaluation is #3 by gas (12.7%) despite only 478K calls, because each call costs 50,000 gas
- Fixed cost, no variability — every KZG proof verification costs the same
- Callers are blob submitters: L2 sequencers and DA protocols

</Section>
