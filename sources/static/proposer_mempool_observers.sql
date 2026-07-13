SELECT
    sample_date,
    strict_candidates,
    xatu_matches,
    seen_by_two_nodes_and_countries,
    median_xatu_lead_ms,
    round(match_pct, 3) AS match_pct,
    round(two_node_country_pct, 3) AS two_node_country_pct
FROM read_parquet('https://data.ethpandaops.io/notebooks/investigations/proposer-mempool-omissions/observer_crosscheck.parquet')
ORDER BY sample_date ASC
