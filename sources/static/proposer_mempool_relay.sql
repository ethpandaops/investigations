SELECT
    relay_observed,
    payload_classification,
    blocks,
    selected,
    omitted,
    opportunities,
    round(omission_pct, 3) AS omission_pct
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/relay_summary.parquet')
ORDER BY relay_observed ASC
