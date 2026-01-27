-- Snooper newPayload overhead distribution (2026-01-26)
-- Buckets overhead into ranges for histogram visualization
SELECT
    multiIf(
        overhead < 0, '< 0',
        overhead < 2, '0-2',
        overhead < 4, '2-4',
        overhead < 6, '4-6',
        overhead < 8, '6-8',
        overhead < 10, '8-10',
        overhead < 15, '10-15',
        overhead < 20, '15-20',
        overhead < 50, '20-50',
        '50+'
    ) as overhead_range,
    count() as calls,
    round(count() * 100.0 / sum(count()) OVER (), 1) as pct
FROM (
    SELECT
        toInt64(ce.duration_ms) - toInt64(ee.duration_ms) as overhead
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
)
GROUP BY overhead_range
ORDER BY
    CASE overhead_range
        WHEN '< 0' THEN 0
        WHEN '0-2' THEN 1
        WHEN '2-4' THEN 2
        WHEN '4-6' THEN 3
        WHEN '6-8' THEN 4
        WHEN '8-10' THEN 5
        WHEN '10-15' THEN 6
        WHEN '15-20' THEN 7
        WHEN '20-50' THEN 8
        WHEN '50+' THEN 9
    END
