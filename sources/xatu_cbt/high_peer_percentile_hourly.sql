-- Hourly percentile ranking of our high-peer node
-- Shows p25, median, mean, p75 percentile rankings
WITH block_rankings AS (
    SELECT
        toStartOfHour(slot_start_date_time) as hour,
        slot,
        block_root,
        node_id,
        seen_slot_start_diff,
        row_number() OVER (PARTITION BY slot, block_root ORDER BY seen_slot_start_diff ASC) as rank,
        count() OVER (PARTITION BY slot, block_root) as total_nodes
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
),
our_node_percentiles AS (
    SELECT
        hour,
        slot,
        block_root,
        (1 - (rank - 1) / total_nodes) * 100 as percentile
    FROM block_rankings
    WHERE node_id = 'utility-mainnet-prysm-geth-tysm-003'
)
SELECT
    hour,
    round(quantile(0.25)(percentile), 1) as "P25",
    round(median(percentile), 1) as "Median",
    round(avg(percentile), 1) as "Mean",
    round(quantile(0.75)(percentile), 1) as "P75"
FROM our_node_percentiles
GROUP BY hour
ORDER BY hour ASC
