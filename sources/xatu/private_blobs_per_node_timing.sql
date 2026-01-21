-- Per-node head timing comparison: SUCCESS vs EMPTY getBlobs outcomes
-- Only includes slots where both outcomes occurred (controlled comparison)
-- Fixed time window: 2026-01-17 to 2026-01-21
SELECT
    g.status as getblobs_status,
    count() as observations,
    countDistinct(g.slot) as unique_slots,
    round(avg(h.head_time_ms), 1) as avg_head_time_ms,
    round(quantile(0.5)(h.head_time_ms), 1) as median_head_time_ms,
    round(quantile(0.25)(h.head_time_ms), 1) as p25_head_time_ms,
    round(quantile(0.75)(h.head_time_ms), 1) as p75_head_time_ms,
    round(quantile(0.95)(h.head_time_ms), 1) as p95_head_time_ms
FROM (
    SELECT slot, block_root, meta_client_name, status
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
      AND status IN ('SUCCESS', 'EMPTY')
) g
INNER JOIN (
    -- Only include slots that have BOTH outcomes (controlled comparison)
    SELECT slot, block_root
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
      AND status IN ('SUCCESS', 'EMPTY')
    GROUP BY slot, block_root
    HAVING countIf(status = 'SUCCESS') > 0 AND countIf(status = 'EMPTY') > 0
) m ON g.slot = m.slot AND g.block_root = m.block_root
INNER JOIN (
    SELECT
        slot,
        block as block_root,
        meta_client_name,
        min(propagation_slot_start_diff) as head_time_ms
    FROM beacon_api_eth_v1_events_head
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
    GROUP BY slot, block, meta_client_name
) h ON g.slot = h.slot AND g.block_root = h.block_root AND g.meta_client_name = h.meta_client_name
GROUP BY g.status
ORDER BY g.status
