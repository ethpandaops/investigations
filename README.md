# ethPandaOps Notebooks

Ethereum blockchain analysis notebooks powered by [Evidence.dev](https://evidence.dev) and [Xatu](https://github.com/ethpandaops/xatu) data.

## Live Site

https://ethpandaops.github.io/notebooks

## Investigation Types

### Live Investigations

Query ClickHouse at build time, refreshed daily at 6:00 UTC.

- Use when data needs to be current
- Queries run during GitHub Actions build
- Results cached until next build

### Point-in-Time Investigations

Use pre-baked parquet files from R2 for reproducibility.

- Use for specific analyses with fixed time ranges
- Data uploaded to `data.ethpandaops.io/notebooks/investigations/{slug}/`
- Loaded via DuckDB `read_parquet()`

## Local Development

### Prerequisites

- Node.js 18+
- npm 7+

### Setup

```bash
npm install
```

### Environment Variables

For live ClickHouse queries, set these environment variables:

```bash
export XATU_HOST=your-host
export XATU_PORT=8443
export XATU_USER=your-user
export XATU_PASSWORD=your-password

export XATU_CBT_HOST=your-cbt-host
export XATU_CBT_PORT=8443
export XATU_CBT_USER=your-cbt-user
export XATU_CBT_PASSWORD=your-cbt-password
```

### Run Development Server

```bash
npm run sources  # Fetch data from sources
npm run dev      # Start dev server
```

Visit http://localhost:3000

### Build for Production

```bash
npm run build
npm run preview  # Preview production build
```

## Directory Structure

```
notebooks/
├── .github/workflows/deploy.yml   # GitHub Pages deployment
├── sources/
│   ├── xatu/connection.yaml       # Raw Xatu ClickHouse
│   ├── xatu_cbt/connection.yaml   # Pre-aggregated ClickHouse
│   └── static/connection.yaml     # DuckDB for R2 parquet
├── pages/
│   ├── index.md                   # Homepage
│   └── investigations/            # Investigation pages
├── evidence.config.yaml           # Evidence configuration
├── evidence.plugins.yaml          # Plugin configuration
└── package.json
```

## Creating New Investigations

**Sidebar auto-populates from folder structure** - just create a new investigation folder and it appears in navigation automatically.

Use the Claude Code `/create-investigation` skill for guided creation.

### Manual Creation

1. Create page at `pages/investigations/{slug}/index.md`
2. Add frontmatter with `title`, `sidebar_position`, and `description`
3. For point-in-time: upload data to R2 and create SQL source in `sources/static/`
4. Test locally with `npm run dev`
5. Commit and push to deploy

### Investigation Frontmatter

```yaml
---
title: My Investigation
sidebar_position: 5           # Lower = higher in sidebar
description: Brief description
---
```

## Data Sources

### xatu_cbt (Pre-aggregated)

- `canonical_beacon_block`
- `canonical_beacon_block_proposer_slashing`
- `canonical_beacon_block_attester_slashing`
- `canonical_beacon_block_execution_transaction`
- `canonical_beacon_blob_sidecar`
- And more...

### xatu (Raw)

Raw event data from Xatu sentries and relays.

### static (DuckDB)

Load parquet files from R2:

```sql
SELECT * FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/{slug}/data.parquet')
```

## Deployment

Automated via GitHub Actions:

- **Trigger**: Push to `master`, daily at 6:00 UTC, or manual dispatch
- **Build**: Queries ClickHouse, generates static site
- **Deploy**: GitHub Pages at `ethpandaops.github.io/notebooks`

### Required Secrets

| Secret | Description |
|--------|-------------|
| `XATU_HOST` | Xatu ClickHouse host |
| `XATU_PORT` | Xatu ClickHouse port |
| `XATU_USER` | Xatu ClickHouse username |
| `XATU_PASSWORD` | Xatu ClickHouse password |
| `XATU_CBT_HOST` | Xatu-CBT ClickHouse host |
| `XATU_CBT_PORT` | Xatu-CBT ClickHouse port |
| `XATU_CBT_USER` | Xatu-CBT ClickHouse username |
| `XATU_CBT_PASSWORD` | Xatu-CBT ClickHouse password |

## License

MIT
