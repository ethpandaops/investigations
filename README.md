# ethPandaOps Notebooks

Ethereum network analysis using [Evidence.dev](https://evidence.dev) and [Xatu](https://github.com/ethpandaops/xatu) data.

**Live site:** https://ethpandaops.github.io/investigations

## Local development

Requires Node.js 18+ and npm 7+.

```bash
npm install
```

For live ClickHouse queries, set environment variables:

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

Run the dev server:

```bash
npm run sources  # Fetch data
npm run dev      # Start server at localhost:3000
```

## Directory structure

```
notebooks/
├── pages/
│   ├── index.md              # Homepage
│   ├── YYYY-MM/{slug}/       # Investigation pages (e.g., 2026-01/timing-games/)
│   └── dashboards/           # Dashboard pages
├── sources/
│   ├── xatu/                 # Raw Xatu ClickHouse
│   ├── xatu_cbt/             # Pre-aggregated ClickHouse
│   └── static/               # DuckDB for R2 parquet files
└── components/               # Svelte components
```

## Creating investigations

Pages are organized by month: `pages/YYYY-MM/{slug}/index.md`

The sidebar auto-populates from folder structure.

### Frontmatter

```yaml
---
title: My Investigation
sidebar_position: 5           # Lower = higher in sidebar
description: Brief description
---
```

### Data sources

**Live queries** (ClickHouse, refreshed daily at build):
- `xatu` - Raw event data from sentries and relays
- `xatu_cbt` - Pre-aggregated canonical beacon tables

**Point-in-time** (DuckDB, for reproducible snapshots):
```sql
SELECT * FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/{slug}/data.parquet')
```

## Deployment

GitHub Actions builds and deploys on push to `master` and daily at 6:00 UTC.

Required secrets: `XATU_PASSWORD`, `XATU_CBT_PASSWORD`

## License

MIT
