-- Per-hour newPayload overhead by EL client (2026-01-26)
-- Aggregates per-slot data into hourly buckets for visualization
SELECT
    toStartOfHour(ee.event_date_time) as hour,
    extractAll(ee.meta_client_name, '-(besu|erigon|geth|nethermind|reth|ethrex)-')[1] as el_client,
    round(avg(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)), 2) as avg_overhead_ms,
    round(quantile(0.5)(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)), 2) as p50_overhead_ms,
    round(quantile(0.95)(toInt64(ce.duration_ms) - toInt64(ee.duration_ms)), 2) as p95_overhead_ms,
    count() as samples
FROM execution_engine_new_payload ee
GLOBAL INNER JOIN consensus_engine_api_new_payload ce
    ON ee.block_hash = ce.block_hash
    AND ee.meta_client_name = ce.meta_client_name
    AND ee.meta_network_name = ce.meta_network_name
WHERE ee.meta_network_name = 'mainnet'
  AND ee.event_date_time >= '2026-01-26 00:00:00'
  AND ee.event_date_time < '2026-01-27 00:00:00'
  AND ee.meta_client_name LIKE '%7870%'
  AND ee.source = 'ENGINE_SOURCE_SNOOPER'
  AND extractAll(ee.meta_client_name, '-(besu|erigon|geth|nethermind|reth|ethrex)-')[1] != ''
GROUP BY hour, el_client
ORDER BY hour ASC, el_client ASC
