-- Daily percentile ranking for the high-peer TYSM node
-- Simplified version without window functions for better performance
WITH node_ranks AS (
    SELECT
        toDate(slot_start_date_time) as day,
        slot,
        block_root,
        node_id,
        seen_slot_start_diff,
        ROW_NUMBER() OVER (PARTITION BY slot, block_root ORDER BY seen_slot_start_diff ASC) as rank,
        COUNT(*) OVER (PARTITION BY slot, block_root) as total_nodes
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
)
SELECT
    day,
    round(median((total_nodes - rank + 1) * 100.0 / total_nodes), 1) as median_percentile,
    round(avg((total_nodes - rank + 1) * 100.0 / total_nodes), 1) as mean_percentile,
    round(quantile(0.25)((total_nodes - rank + 1) * 100.0 / total_nodes), 1) as p25_percentile,
    round(quantile(0.75)((total_nodes - rank + 1) * 100.0 / total_nodes), 1) as p75_percentile,
    count(*) as block_count
FROM node_ranks
WHERE node_id = 'utility-mainnet-prysm-geth-tysm-003'
GROUP BY day
ORDER BY day ASC
