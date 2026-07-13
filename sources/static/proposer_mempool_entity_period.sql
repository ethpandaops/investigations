SELECT
    period,
    period_start,
    period_end_exclusive,
    period_label,
    proposer_entity,
    blocks,
    selected,
    omitted,
    opportunities,
    round(omission_pct, 3) AS omission_pct,
    round(expected_omission_pct, 3) AS expected_omission_pct,
    round(builder_adjusted_ratio, 3) AS builder_adjusted_ratio
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/proposer_period.parquet')
ORDER BY period ASC, proposer_entity ASC
