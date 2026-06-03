---
title: When Self-Built Blocks Arrive
sidebar_position: 1
description: How far into the slot does a locally-built block reach the network, and how does it compare to relay-delivered blocks?
date: 2026-06-03T11:00:00Z
author: samcm
tags:
  - block-timing
  - mev
  - self-built
  - relays
  - validators
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    const C_LOCAL = '#2563eb';
    const C_RELAY = '#ef4444';
    const C_UNREG = '#16a34a';

    // Cumulative arrival (CDF), 3 groups split by relay registration
    $: splitCdfConfig = (() => {
        if (!three_series || three_series.length === 0 || three_series[0].cdf_pct == null) return {};
        const order = ['Self-built, not registered', 'Self-built, registered', 'Relay (MEV-Boost)'];
        const colors = { 'Self-built, not registered': C_UNREG, 'Self-built, registered': C_LOCAL, 'Relay (MEV-Boost)': C_RELAY };
        const mk = (g) => three_series.filter(d => d.grp === g).map(d => [Number(d.bucket_s), Number(d.cdf_pct)]);
        return {
            title: { text: 'Cumulative Arrival by Group', subtext: 'Share of each group that has reached the network by time t', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis',
                formatter: (ps) => `by ${Number(ps[0].axisValue).toFixed(1)}s<br/>` +
                    ps.map(p => `${p.marker} ${p.seriesName}: <b>${Number(p.value[1]).toFixed(0)}%</b>`).join('<br/>') },
            legend: { data: order, top: 44, type: 'scroll' },
            grid: { left: 12, right: 22, bottom: 58, top: 92, containLabel: true },
            xAxis: { type: 'value', min: 0, max: 4, name: 'Time into slot (seconds)', nameLocation: 'center', nameGap: 32,
                axisLabel: { formatter: '{value}s' }, splitLine: { show: false } },
            yAxis: { type: 'value', min: 0, max: 100, name: 'Blocks arrived (%)', nameLocation: 'center', nameGap: 38, nameRotate: 90,
                axisLabel: { formatter: '{value}%' }, splitLine: { lineStyle: { color: '#f0f0f0' } } },
            series: order.map(g => ({
                name: g, type: 'line', smooth: true, showSymbol: false, data: mk(g),
                lineStyle: { width: 3, color: colors[g] }, itemStyle: { color: colors[g] }
            }))
        };
    })();

    // Per-operator median arrival, self-built vs relay
    $: entityConfig = (() => {
        if (!by_entity || by_entity.length === 0 || by_entity[0].local_p50_s == null) return {};
        const rows = [...by_entity].sort((a, b) => Number(b.local_p50_s) - Number(a.local_p50_s)); // slowest at top
        const names = rows.map(d => d.entity);
        return {
            title: { text: 'Median Arrival by Operator', subtext: 'Self-built vs relay-delivered, operators with ≥100 self-built blocks', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: (v) => (v == null ? 'n/a' : Number(v).toFixed(3) + 's') },
            legend: { data: ['Self-built', 'Relay'], top: 50 },
            grid: { left: 12, right: 40, bottom: 44, top: 92, containLabel: true },
            xAxis: { type: 'value', name: 'Median arrival into slot (seconds)', nameLocation: 'center', nameGap: 30,
                axisLabel: { formatter: '{value}s' }, splitLine: { lineStyle: { color: '#f0f0f0' } } },
            yAxis: { type: 'category', data: names, axisLabel: { fontSize: 10 } },
            series: [
                { name: 'Self-built', type: 'bar', data: rows.map(d => Number(d.local_p50_s)),
                    itemStyle: { color: C_LOCAL, borderRadius: [0, 3, 3, 0] }, barGap: '10%' },
                { name: 'Relay', type: 'bar', data: rows.map(d => d.relay_p50_s == null ? null : Number(d.relay_p50_s)),
                    itemStyle: { color: C_RELAY, borderRadius: [0, 3, 3, 0] } }
            ]
        };
    })();

    // Self-built split by relay registration: 3 smooth-area series
    $: splitConfig = (() => {
        if (!three_series || three_series.length === 0 || three_series[0].pct == null) return {};
        const order = ['Self-built, not registered', 'Self-built, registered', 'Relay (MEV-Boost)'];
        const colors = { 'Self-built, not registered': C_UNREG, 'Self-built, registered': C_LOCAL, 'Relay (MEV-Boost)': C_RELAY };
        const mk = (g) => three_series.filter(d => d.grp === g).map(d => [Number(d.bucket_s), Number(d.pct)]);
        return {
            title: { text: 'Self-Built Arrival, Split by Relay Registration', subtext: 'Share of group blocks per 100ms, May 2026', left: 'center', textStyle: { fontSize: 15, fontWeight: 600 }, subtextStyle: { fontSize: 11, color: '#888' } },
            tooltip: { trigger: 'axis',
                formatter: (ps) => `${Number(ps[0].axisValue).toFixed(1)}s into slot<br/>` +
                    ps.map(p => `${p.marker} ${p.seriesName}: <b>${Number(p.value[1]).toFixed(1)}%</b>`).join('<br/>') },
            legend: { data: order, top: 44, type: 'scroll' },
            grid: { left: 12, right: 22, bottom: 58, top: 92, containLabel: true },
            xAxis: { type: 'value', min: 0, max: 4, name: 'Arrival into slot (seconds)', nameLocation: 'center', nameGap: 32,
                axisLabel: { formatter: '{value}s' }, splitLine: { show: false } },
            yAxis: { type: 'value', name: 'Share of group blocks (%)', nameLocation: 'center', nameGap: 38, nameRotate: 90,
                axisLabel: { formatter: '{value}%' }, splitLine: { lineStyle: { color: '#f0f0f0' } } },
            series: order.map(g => ({
                name: g, type: 'line', smooth: true, showSymbol: false, data: mk(g),
                lineStyle: { width: 2.5, color: colors[g] }, itemStyle: { color: colors[g] },
                areaStyle: { color: colors[g], opacity: 0.15 }
            }))
        };
    })();
</script>

<PageMeta
    date="2026-06-03T11:00:00Z"
    author="samcm"
    tags={["block-timing", "mev", "self-built", "relays"]}
    networks={["Ethereum Mainnet"]}
    startTime="2026-05-01T00:00:00Z"
    endTime="2026-05-31T23:59:59Z"
/>

```sql share
select * from xatu_cbt.self_built_share
```

```sql by_entity
select * from xatu_cbt.self_built_by_entity order by local_p50_s asc
```

```sql three_series
with c as (
    select
        case when p.source = 'relay' then 'Relay (MEV-Boost)'
             when r.validator_index is not null then 'Self-built, registered'
             else 'Self-built, not registered' end as grp,
        least(floor(p.arr_ms / 100.0) * 100, 4000) / 1000.0 as bucket_s
    from xatu_cbt.self_built_block_proposers p
    left join xatu.self_built_registered_validators r on p.validator_index = r.validator_index
),
tot as (select grp, count(*) as n from c group by grp),
buck as (select grp, bucket_s, count(*) as n from c group by grp, bucket_s),
grid as (select g.grp, x / 10.0 as bucket_s from (select distinct grp from c) g cross join range(0, 41) t(x))
select gr.grp as grp, gr.bucket_s as bucket_s,
    round(100.0 * coalesce(b.n, 0) / t.n, 4) as pct,
    round(100.0 * sum(coalesce(b.n, 0)) over (partition by gr.grp order by gr.bucket_s) / t.n, 3) as cdf_pct
from grid gr
left join buck b on gr.grp = b.grp and gr.bucket_s = b.bucket_s
join tot t on gr.grp = t.grp
order by gr.grp, gr.bucket_s
```

```sql split_summary
with c as (
    select
        case when p.source = 'relay' then 'Relay (MEV-Boost)'
             when r.validator_index is not null then 'Self-built, registered'
             else 'Self-built, not registered' end as grp,
        p.arr_ms / 1000.0 as s
    from xatu_cbt.self_built_block_proposers p
    left join xatu.self_built_registered_validators r on p.validator_index = r.validator_index
)
select grp,
    count(*) as blocks,
    round(100.0 * count(*) / sum(count(*)) over (), 1) as pct_of_blocks,
    round(quantile_cont(s, 0.50), 3) as median_s
from c group by grp
order by median_s
```

<Section type="question">

## Question

When a validator builds its own block locally instead of buying one from an MEV-Boost relay, how far into the slot does that block reach the network, and how does its timing compare to relay-delivered blocks?

</Section>

<Section type="background">

## Background

You can't tell a **self-built** block from a relay block by looking at it, so we cross-reference every canonical block against the relays: if no monitored relay reports delivering it, we call it **locally built**. Arrival is the earliest a Xatu sentry saw the block on gossip (`seen_slot_start_diff`), measured from slot start. Window: **all of May 2026**, 222,430 mainnet blocks.

</Section>

<Section type="investigation">

## Investigation

### How Many Blocks Are Self-Built

<BigValue
    data={share}
    value="pct_local_frac"
    fmt="pct1"
    title="Self-built share"
/>

<BigValue
    data={share}
    value="local_blocks"
    fmt="num0"
    title="Locally-built blocks"
/>

<BigValue
    data={share}
    value="relay_blocks"
    fmt="num0"
    title="Relay-delivered blocks"
/>

### Registered vs Unregistered Self-Builders

Split self-built blocks by whether the proposer is registered with any relay and two populations fall out. **~80% come from validators registered with relays**: MEV-Boost users whose relay path lost the slot, so they shipped local. They land at ~1.45s, right on the relay curve, because they waited the same ~1s for bids first (the min-bid fallback). The other ~20%, with no relay registration, have nothing to wait for and publish almost immediately, at ~0.51s.

<SqlSource source="xatu_cbt" query="self_built_block_proposers" />

<ECharts config={splitConfig} height="480px" />

<DataTable data={split_summary}>
    <Column id="grp" title="Group" />
    <Column id="blocks" title="Blocks" fmt="num0" />
    <Column id="pct_of_blocks" title="% of all blocks" fmt="num1" />
    <Column id="median_s" title="Median arrival (s)" fmt="num3" />
</DataTable>

Same split, cumulative: the not-registered group is mostly on the network by 1s, while registered self-builders track the relay curve.

<ECharts config={splitCdfConfig} height="440px" />

Method: a validator counts as registered if it appears in any relay's registration feed over the year to June 2026 (99.3% of relay proposers do, as they must). Capture is imperfect, so a few "not registered" blocks may be misclassified, which only narrows the gap.

### Who Self-Builds, And When

Self-built timing also varies a lot by operator, from ~0.26s to ~3.0s. ether.fi ships self-built blocks at ~0.4s; coinbase and kiln drag up near 2.5 to 3.0s.

<SqlSource source="xatu_cbt" query="self_built_by_entity" />

<ECharts config={entityConfig} height="720px" />

<DataTable data={by_entity} rows=25>
    <Column id="entity" title="Operator" />
    <Column id="local_blocks" title="Self-built blocks" fmt="num0" />
    <Column id="relay_blocks" title="Relay blocks" fmt="num0" />
    <Column id="pct_local" title="Self-built %" fmt="num1" />
    <Column id="local_p50_s" title="Self-built median (s)" fmt="num3" />
    <Column id="relay_p50_s" title="Relay median (s)" fmt="num3" />
</DataTable>

</Section>

<Section type="takeaways">

## Takeaways

- Only ~6.7% of canonical mainnet blocks are locally built; the rest come via relays.
- ~80% of those self-built blocks are from MEV-Boost validators that fell back to local after the relay lost; they land at ~1.45s (the relay median), having waited the same ~1s for bids. The other ~20%, not registered with any relay, ship at ~0.51s.
- Self-built timing is highly operator-dependent, from ~0.26s to ~3.0s.

</Section>
