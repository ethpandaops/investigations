---
title: Example Snapshot Investigation
sidebar_position: 99
description: Demonstrates point-in-time data analysis pattern
---

# Example Point-in-Time Investigation

<Alert status="info">
This is a **point-in-time investigation** - data is loaded from a pre-baked parquet file stored in R2 for reproducibility.
</Alert>

This demonstrates the pattern for creating investigations with static data snapshots.

## How Point-in-Time Investigations Work

1. **Data Collection**: Query data using the xatu-mcp tool
2. **Export**: Save results as parquet file
3. **Upload**: Store in R2 at `data.ethpandaops.io/notebooks/investigations/{slug}/`
4. **Reference**: Load via DuckDB `read_parquet()` in Evidence

## Example Query Pattern

When this investigation has real data, it would use a SQL file like:

```sql
-- sources/static/example_snapshot_data.sql
SELECT * FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/example-snapshot/data.parquet')
```

## Creating Your Own

Use the `/create-investigation` Claude skill to create new investigations. It will guide you through:

- Gathering requirements (title, type, network, time range)
- For point-in-time: Querying data via xatu-mcp and uploading to R2
- Creating the SQL source file
- Creating the investigation page
- Updating the homepage

## Placeholder Visualization

Once data is available, you would add visualizations like:

```
<LineChart
    data={example_data}
    x="timestamp"
    y="value"
    title="Example Metric Over Time"
/>
```

---

<Alert status="warning">
This is a template investigation. Replace with real data from R2.
</Alert>
