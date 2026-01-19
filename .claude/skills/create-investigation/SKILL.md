# Create Investigation Skill

This skill guides the creation of new investigation pages for the ethPandaOps notebooks site.

## Trigger

User says `/create-investigation` or asks to create a new investigation/analysis page.

## Workflow

### Step 1: Gather Requirements

Ask the user for:

1. **Title**: Investigation title (e.g., "Block Timing Analysis")
2. **Slug**: URL-safe identifier (e.g., "block-timing-analysis")
3. **Type**:
   - `live` - Queries ClickHouse at build time, refreshed daily
   - `point-in-time` - Uses pre-baked parquet data from R2 for reproducibility
4. **Network**: mainnet, sepolia, holesky, etc.
5. **Time Range**: For point-in-time investigations
6. **Description**: Brief description of what this investigation analyzes

### Step 2: For Point-in-Time Investigations

If the user selected `point-in-time`:

1. **Query the data** using xatu-mcp:
   ```python
   # In xatu-mcp session
   from xatu import clickhouse, storage

   # Query the data
   df = clickhouse.query('xatu-cbt', '''
       SELECT ...
       FROM table
       WHERE slot_start_date_time >= '...'
       AND slot_start_date_time < '...'
   ''')

   # Save locally
   df.to_parquet('/workspace/data.parquet')

   # Upload to R2
   url = storage.upload(
       '/workspace/data.parquet',
       'notebooks/investigations/{slug}/data.parquet'
   )
   ```

2. **Create SQL source file** at `sources/static/{slug}_data.sql`:
   ```sql
   SELECT * FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/{slug}/data.parquet')
   ```

### Step 3: Create Investigation Page

Create the investigation page at `pages/investigations/{slug}/index.md`:

```markdown
---
title: {Title}
sidebar_position: {N}
description: {Brief description for sidebar hover}
---

# {Title}

<Alert status="info">
This is a **{type} investigation** - {type description}
</Alert>

{Description and context}

## Analysis

{SQL queries and visualizations}

## Key Findings

{Summary of insights}

---

<Alert status="warning">
{For live: "Data refreshed daily at 6:00 UTC."}
{For point-in-time: "Data snapshot from {date}. Analysis is reproducible."}
</Alert>
```

**Frontmatter fields:**
- `title`: Shown in sidebar and page header
- `sidebar_position`: Lower numbers appear higher (use 1-98 for real investigations, 99 for templates)
- `description`: Shown on hover in sidebar

### Step 4: Sidebar Auto-Population

**No manual homepage update needed!** The sidebar automatically populates from the folder structure in `pages/investigations/`.

If you want to feature the investigation on the investigations landing page, optionally add it to `pages/investigations/index.md`:

```markdown
<BigLink href="/investigations/{slug}">
  <span slot="title">{Title}</span>
  <span slot="description">{Description}</span>
</BigLink>
```

### Step 5: Commit and Deploy

```bash
cd /Users/samcm/go/src/github.com/ethpandaops/notebooks
git add .
git commit -m "feat: add {title} investigation"
git push
```

## Data Sources Available

### Live Sources (ClickHouse)

- **xatu_cbt**: Pre-aggregated canonical beacon tables
  - `canonical_beacon_block`
  - `canonical_beacon_block_proposer_slashing`
  - `canonical_beacon_block_attester_slashing`
  - `canonical_beacon_block_bls_to_execution_change`
  - `canonical_beacon_block_execution_transaction`
  - `canonical_beacon_block_voluntary_exit`
  - `canonical_beacon_block_deposit`
  - `canonical_beacon_block_withdrawal`
  - `canonical_beacon_blob_sidecar`

- **xatu**: Raw event data tables

### Static Sources (DuckDB/R2)

- Pattern: `read_parquet('https://data.ethpandaops.io/notebooks/investigations/{slug}/data.parquet')`
- Use for reproducible point-in-time snapshots

## Evidence Components Available

- `<LineChart>`, `<BarChart>`, `<AreaChart>`, `<ScatterPlot>`
- `<BigValue>`, `<Value>`
- `<DataTable>`
- `<Alert>`, `<Details>`
- `<Grid>`, `<BigLink>`
- `<Dropdown>`, `<TextInput>`, `<DateRange>`

## Example Queries

### Block timing (live from xatu_cbt)
```sql
SELECT
    toStartOfHour(slot_start_date_time) as hour,
    count() as block_count,
    avg(block_total_bytes) as avg_block_size
FROM xatu_cbt.canonical_beacon_block_execution_transaction
WHERE slot_start_date_time >= now() - INTERVAL 7 DAY
GROUP BY hour
ORDER BY hour
```

### Blob analysis (live from xatu_cbt)
```sql
SELECT
    toDate(slot_start_date_time) as date,
    count() as blob_count,
    sum(blob_size) as total_blob_bytes
FROM xatu_cbt.canonical_beacon_blob_sidecar
WHERE slot_start_date_time >= now() - INTERVAL 30 DAY
GROUP BY date
ORDER BY date
```

## Notes

- **Sidebar auto-populates** from folder structure - just create the page!
- Always test locally with `npm run dev` before pushing
- For point-in-time investigations, ensure data is uploaded to R2 before deploying
- Use meaningful commit messages that describe the investigation
- Use `sidebar_position` to control ordering (lower = higher in list)
