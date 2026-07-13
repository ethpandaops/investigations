SELECT
    proposer_entity,
    target,
    method,
    selected,
    omitted,
    opportunities,
    periods,
    round(omission_pct, 3) AS omission_pct
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/target_top.parquet')
ORDER BY omitted DESC
