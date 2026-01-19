---
sidebar_position: 1
---

Real-time overview of Ethereum mainnet health and performance metrics.

```sql network_stats
select * from xatu.network_stats
```

## Block Production (Last 7 Days)

<LineChart
    data={network_stats}
    x="date"
    y="total_blocks"
    title="Daily Block Count"
/>

## Block Size Trend

<AreaChart
    data={network_stats}
    x="date"
    y="avg_block_size_kb"
    title="Average Block Size (KB)"
/>

## Transactions Per Block

<BarChart
    data={network_stats}
    x="date"
    y="avg_txs_per_block"
    title="Average Transactions Per Block"
/>

## Summary Metrics

<BigValue
    data={network_stats}
    value="total_blocks"
    title="Total Blocks (7d)"
    fmt="num0"
/>

<BigValue
    data={network_stats}
    value="avg_block_size_kb"
    title="Avg Block Size"
    fmt="num1"
    suffix=" KB"
/>

<BigValue
    data={network_stats}
    value="avg_txs_per_block"
    title="Avg Txs/Block"
    fmt="num1"
/>
