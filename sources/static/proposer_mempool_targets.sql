SELECT
    proposer_entity,
    target,
    method,
    qualified_periods,
    elevated_periods,
    high_rate_periods,
    selected,
    omitted,
    opportunities,
    round(median_omission_pct, 3) AS median_omission_pct,
    round(median_rate_ratio, 3) AS median_rate_ratio,
    round(max_rate_ratio, 3) AS max_rate_ratio,
    consistent_elevation,
    recurring_high_rate
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/target_persistence.parquet')
ORDER BY omitted DESC
