SELECT
    builder_pubkey,
    builder_short,
    blocks,
    selected,
    omitted,
    opportunities,
    round(omission_pct, 3) AS omission_pct
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/builder_summary.parquet')
ORDER BY opportunities DESC
