-- Unavailable blobs detail
-- Lists entities that submitted blobs where NO node had it in their mempool when the block arrived
-- Fixed time window: 2026-01-17 to 2026-01-21
WITH getblobs_by_blob AS (
    SELECT
        slot,
        arrayJoin(versioned_hashes) AS versioned_hash,
        countIf(status = 'SUCCESS') AS success_nodes
    FROM consensus_engine_api_get_blobs
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= '2026-01-17 00:00:00'
      AND slot_start_date_time < '2026-01-21 00:00:00'
      AND requested_count > 0
    GROUP BY slot, versioned_hash
),
truly_private AS (
    SELECT versioned_hash
    FROM getblobs_by_blob
    GROUP BY versioned_hash
    HAVING sum(success_nodes) = 0
),
block_blobs AS (
    SELECT
        `from` AS sender_address,
        arrayJoin(blob_hashes) AS versioned_hash,
        slot_start_date_time
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
    b.sender_address AS address,
    count() AS private_blobs
FROM block_blobs b
INNER JOIN truly_private tp ON b.versioned_hash = tp.versioned_hash
LEFT JOIN submitter_names s ON lower(b.sender_address) = s.address_clean
GROUP BY submitter_name, b.sender_address
ORDER BY private_blobs DESC
