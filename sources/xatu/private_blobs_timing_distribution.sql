-- Head timing distribution for SUCCESS vs EMPTY getBlobs
-- Shows where the timing penalty comes from
-- Fixed time window: 2026-01-17 to 2026-01-21
WITH mixed_slots AS (
    SELECT slot, block_root
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
      AND status IN ('SUCCESS', 'EMPTY')
    GROUP BY slot, block_root
    HAVING countIf(status = 'SUCCESS') > 0 AND countIf(status = 'EMPTY') > 0
)
SELECT
    g.status as getblobs_status,
    CASE
        WHEN h.head_time_ms < 1000 THEN '< 1s'
        WHEN h.head_time_ms < 1500 THEN '1-1.5s'
        WHEN h.head_time_ms < 2000 THEN '1.5-2s'
        WHEN h.head_time_ms < 2500 THEN '2-2.5s'
        WHEN h.head_time_ms < 3000 THEN '2.5-3s'
        WHEN h.head_time_ms < 4000 THEN '3-4s'
        ELSE '> 4s'
    END as timing_bucket,
    count() as observations
FROM (
    SELECT slot, block_root, meta_client_name, status
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
      AND status IN ('SUCCESS', 'EMPTY')
) g
INNER JOIN mixed_slots m ON g.slot = m.slot AND g.block_root = m.block_root
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
GROUP BY g.status, timing_bucket
ORDER BY g.status, timing_bucket
