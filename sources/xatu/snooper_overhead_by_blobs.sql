-- Snooper overhead by blob count (Jan 16, 2026)
-- Shows how serialization overhead scales with number of blobs
SELECT
    toUInt8(length(ee.versioned_hashes)) as blob_count,
    count() as calls,
    round(avg(ee.duration_ms), 2) as avg_el_ms,
    round(avg(ce.duration_ms), 2) as avg_cl_ms,
    round(avg(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)), 2) as overhead_ms,
    round(sum(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)) / sum(length(ee.versioned_hashes)), 2) as per_blob_ms
FROM execution_engine_get_blobs ee
GLOBAL INNER JOIN consensus_engine_api_get_blobs ce
    ON ee.versioned_hashes = ce.versioned_hashes
    AND ee.meta_client_name = ce.meta_client_name
    AND ee.meta_network_name = ce.meta_network_name
WHERE ee.meta_network_name = 'mainnet'
  AND ee.event_date_time >= '2026-01-16 00:00:00'
  AND ee.event_date_time < '2026-01-17 00:00:00'
  AND ee.meta_client_name LIKE '%7870%'
  AND length(ee.versioned_hashes) > 0
GROUP BY toUInt8(length(ee.versioned_hashes))
ORDER BY blob_count
