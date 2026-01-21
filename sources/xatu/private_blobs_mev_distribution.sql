-- Blob mempool propagation by block source (MEV vs Local)
-- Categorizes slots by mempool propagation success:
--   - All SUCCESS = blobs fully propagated through mempool
--   - Mixed = blobs in mempool but incomplete propagation
--   - All EMPTY = truly private blobs (never in public mempool)
-- Fixed time window: 2026-01-17 to 2026-01-21
WITH getblobs_stats AS (
    SELECT
        slot,
        max(requested_count) as blobs_requested,
        countIf(status = 'SUCCESS') as success_count,
        countIf(status = 'EMPTY') as empty_count,
        count() as node_observations
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
    GROUP BY slot
),
mev AS (
    SELECT DISTINCT slot, 1 as is_mev
    FROM mev_relay_proposer_payload_delivered
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
)
SELECT
    CASE WHEN m.is_mev = 1 THEN 'MEV' ELSE 'Local' END as block_source,
    CASE
        WHEN g.empty_count = 0 THEN 'Full propagation (all SUCCESS)'
        WHEN g.success_count = 0 THEN 'Truly private (all EMPTY)'
        ELSE 'Partial propagation (mixed)'
    END as mempool_status,
    count() as slots,
    round(avg(g.blobs_requested), 1) as avg_blobs,
    round(avg(g.empty_count * 100.0 / g.node_observations), 1) as avg_empty_pct,
    round(avg(g.node_observations), 1) as avg_nodes_observed
FROM getblobs_stats g
LEFT JOIN mev m ON g.slot = m.slot
GROUP BY block_source, mempool_status
ORDER BY block_source DESC, mempool_status
