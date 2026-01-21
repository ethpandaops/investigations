-- getBlobs status distribution for private blobs analysis
-- Shows how often nodes can/cannot retrieve blobs from their EL
SELECT
    status,
    count() as observations,
    round(count() * 100.0 / sum(count()) OVER (), 2) as pct,
    round(avg(requested_count), 1) as avg_blobs_requested,
    round(avg(returned_count), 1) as avg_blobs_returned
FROM consensus_engine_api_get_blobs
WHERE meta_network_name = 'mainnet'
  AND slot_start_date_time >= '2026-01-17 00:00:00'
  AND slot_start_date_time < '2026-01-21 00:00:00'
  AND requested_count > 0
GROUP BY status
ORDER BY observations DESC
