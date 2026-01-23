-- Overall blob availability statistics
-- Fixed time window: 2026-01-17 to 2026-01-21
WITH getblobs_by_blob AS (
    SELECT
        slot,
        arrayJoin(versioned_hashes) AS versioned_hash,
        countIf(status = 'SUCCESS') AS success_nodes,
        countIf(status = 'EMPTY') AS empty_nodes
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
    GROUP BY slot, versioned_hash
),
blob_status AS (
    SELECT
        versioned_hash,
        CASE
            WHEN sum(success_nodes) = 0 THEN 'Unavailable'
            WHEN sum(empty_nodes) = 0 THEN 'Full Propagation'
            ELSE 'Partial Propagation'
        END AS status
    FROM getblobs_by_blob
    GROUP BY versioned_hash
)
SELECT
    status,
    count() AS blob_count,
    round(count() * 100.0 / sum(count()) OVER (), 2) AS pct
FROM blob_status
GROUP BY status
ORDER BY blob_count DESC
