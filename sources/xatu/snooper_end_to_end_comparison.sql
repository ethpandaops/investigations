-- End-to-end impact comparison: Jan 15 (no snooper) vs Jan 16 (with snooper)
-- Compares CL-observed get_blobs duration from consensus_engine_api_get_blobs
SELECT
    extractAll(meta_client_name, '-(besu|erigon|geth|nethermind|reth|ethrex)-')[1] as el_client,
    round(avgIf(duration_ms, toDate(event_date_time) = '2026-01-15'), 2) as jan15_no_snooper_ms,
    round(avgIf(duration_ms, toDate(event_date_time) = '2026-01-16'), 2) as jan16_with_snooper_ms,
    round(avgIf(duration_ms, toDate(event_date_time) = '2026-01-16') - avgIf(duration_ms, toDate(event_date_time) = '2026-01-15'), 2) as delta_ms,
    round((avgIf(duration_ms, toDate(event_date_time) = '2026-01-16') - avgIf(duration_ms, toDate(event_date_time) = '2026-01-15')) / avgIf(duration_ms, toDate(event_date_time) = '2026-01-15') * 100, 1) as delta_pct
FROM consensus_engine_api_get_blobs
WHERE meta_network_name = 'mainnet'
  AND event_date_time >= '2026-01-15 00:00:00'
  AND event_date_time < '2026-01-17 00:00:00'
  AND meta_client_name LIKE '%7870%'
GROUP BY el_client
HAVING el_client != ''
ORDER BY el_client
