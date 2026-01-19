---
title: Block Timing Analysis
sidebar_position: 1
description: Live analysis of Ethereum block timing and propagation
---

# Block Timing Analysis

<Alert status="info">
This is a **live investigation** - data is queried from ClickHouse at build time and refreshed daily.
</Alert>

This analysis examines Ethereum block timing patterns over the last 24 hours.

## Recent Block Statistics

```sql block_stats
SELECT
    toStartOfHour(slot_start_date_time) as hour,
    count() as block_count,
    avg(block_total_bytes) as avg_block_size,
    avg(block_total_bytes_compressed) as avg_block_size_compressed,
    max(slot) as max_slot
FROM xatu_cbt.canonical_beacon_block_execution_transaction
WHERE slot_start_date_time >= now() - INTERVAL 24 HOUR
GROUP BY hour
ORDER BY hour DESC
LIMIT 24
```

<LineChart
    data={block_stats}
    x="hour"
    y="block_count"
    title="Blocks per Hour (Last 24h)"
/>

## Block Size Distribution

<BarChart
    data={block_stats}
    x="hour"
    y="avg_block_size"
    title="Average Block Size by Hour"
/>

## Summary

<BigValue
    data={block_stats}
    value="block_count"
    title="Total Blocks"
    fmt="num0"
/>

<BigValue
    data={block_stats}
    value="avg_block_size"
    title="Avg Block Size"
    fmt="num0"
/>

---

<Alert status="warning">
Data refreshed daily at 6:00 UTC. Last build: {new Date().toISOString()}
</Alert>
