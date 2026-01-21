-- Private blob submitter summary
-- Shows which L2s/entities submit blobs that never reach the public mempool
-- A "truly private" blob = all nodes got EMPTY from engine_getBlobs (never in any mempool)
-- Fixed time window: 2026-01-17 to 2026-01-21
WITH getblobs_by_blob AS (
    SELECT
        slot,
        arrayJoin(versioned_hashes) AS versioned_hash,
        countIf(status = 'SUCCESS') AS success_nodes,
        countIf(status = 'EMPTY') AS empty_nodes,
        count() AS total_nodes
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
    GROUP BY slot, versioned_hash
),
blob_propagation AS (
    SELECT
        versioned_hash,
        avg(empty_nodes * 100.0 / total_nodes) AS avg_empty_rate,
        CASE
            WHEN sum(success_nodes) = 0 THEN 'truly_private'
            WHEN sum(empty_nodes) = 0 THEN 'full_propagation'
            ELSE 'partial_propagation'
        END AS propagation_status
    FROM getblobs_by_blob
    GROUP BY versioned_hash
),
block_blobs AS (
    SELECT
        `from` AS sender_address,
        arrayJoin(blob_hashes) AS versioned_hash
    FROM canonical_beacon_block_execution_transaction
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND length(blob_hashes) > 0
),
submitter_names AS (
    SELECT DISTINCT
        lower(substring(toString(address), 1, 42)) AS address_clean,
        name
    FROM blob_submitter
    WHERE meta_network_name = 'mainnet'
)
SELECT
    COALESCE(s.name, 'Unknown') AS submitter_name,
    count() AS total_blobs,
    countIf(p.propagation_status = 'truly_private') AS truly_private,
    countIf(p.propagation_status = 'partial_propagation') AS partial,
    countIf(p.propagation_status = 'full_propagation') AS full_propagation,
    round(avg(p.avg_empty_rate), 1) AS empty_rate
FROM block_blobs b
LEFT JOIN blob_propagation p ON b.versioned_hash = p.versioned_hash
LEFT JOIN submitter_names s ON lower(b.sender_address) = s.address_clean
WHERE p.versioned_hash IS NOT NULL
GROUP BY submitter_name
HAVING total_blobs >= 100
ORDER BY truly_private DESC, empty_rate DESC
LIMIT 30
