-- Snooper internal overhead by EL client (Jan 16, 2026)
-- Joins execution_engine_get_blobs (snooper) with consensus_engine_api_get_blobs (prysm)
SELECT
    extractAll(ee.meta_client_name, '-(besu|erigon|geth|nethermind|reth|ethrex)-')[1] as el_client,
    count() as calls,
    sum(length(ee.versioned_hashes)) as total_blobs,
    round(avg(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)), 2) as avg_overhead_ms,
    round(quantile(0.5)(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)), 2) as p50_overhead_ms,
    round(quantile(0.95)(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)), 2) as p95_overhead_ms,
    round(sum(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)) / sum(length(ee.versioned_hashes)), 2) as overhead_per_blob_ms
FROM execution_engine_get_blobs ee
GLOBAL INNER JOIN consensus_engine_api_get_blobs ce
    ON ee.versioned_hashes = ce.versioned_hashes
    AND ee.meta_client_name = ce.meta_client_name
    AND ee.meta_network_name = ce.meta_network_name
WHERE ee.meta_network_name = 'mainnet'
  AND ee.event_date_time >= '2026-01-16 00:00:00'
  AND ee.event_date_time < '2026-01-17 00:00:00'
  AND ee.meta_client_name LIKE '%7870%'
GROUP BY el_client
HAVING el_client != ''
ORDER BY el_client
