SELECT
    period,
    period_start,
    period_end_exclusive,
    period_label,
    blocks,
    selected,
    omitted,
    opportunities,
    round(omission_pct, 3) AS omission_pct
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/period_summary.parquet')
ORDER BY period ASC
