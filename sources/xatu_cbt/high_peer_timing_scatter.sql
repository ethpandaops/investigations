-- Per-block timing: our node vs network median
-- For scatter plot visualization
WITH block_stats AS (
    SELECT
        slot,
        median(seen_slot_start_diff) as network_median,
        minIf(seen_slot_start_diff, node_id = 'utility-mainnet-prysm-geth-tysm-003') as our_time
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
    GROUP BY slot
    HAVING our_time > 0
)
SELECT
    slot,
    round(network_median) as network_median_ms,
    round(our_time) as our_time_ms,
    round(our_time - network_median) as diff_ms
FROM block_stats
ORDER BY slot ASC
