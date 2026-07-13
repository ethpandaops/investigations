SELECT
    proposer_entity,
    blocks,
    selected,
    omitted,
    opportunities,
    round(omission_pct, 3) AS omission_pct,
    round(expected_omission_pct, 3) AS expected_omission_pct,
    round(builder_adjusted_ratio, 3) AS builder_adjusted_ratio,
    qualifying_periods,
    periods_over_1_5,
    periods_over_2,
    round(median_period_ratio, 3) AS median_period_ratio,
    round(max_period_ratio, 3) AS max_period_ratio
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/proposer_summary.parquet')
ORDER BY opportunities DESC
