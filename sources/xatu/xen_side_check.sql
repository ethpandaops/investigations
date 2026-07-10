-- Cross-check the measurement: CL-side (tysm caller) vs EL-side (engine snooper) p50 durations
-- Spike: 2026-07-09 09:00-11:00 UTC. Baseline: 2026-07-09 13:00-15:00 UTC. 7870 nodes, VALID only.
SELECT el, side, period, round(quantile(0.5)(d), 1) AS p50_ms, toFloat64(count()) AS calls
FROM (
    SELECT
        meta_execution_implementation AS el,
        'CL (tysm)' AS side,
        if(slot_start_date_time >= toDateTime('2026-07-09 09:00:00', 'UTC')
           AND slot_start_date_time < toDateTime('2026-07-09 11:00:00', 'UTC'), 'spike', 'baseline') AS period,
        duration_ms AS d
    FROM default.consensus_engine_api_new_payload
    WHERE meta_network_name = 'mainnet'
      AND ((slot_start_date_time >= toDateTime('2026-07-09 09:00:00', 'UTC') AND slot_start_date_time < toDateTime('2026-07-09 11:00:00', 'UTC'))
        OR (slot_start_date_time >= toDateTime('2026-07-09 13:00:00', 'UTC') AND slot_start_date_time < toDateTime('2026-07-09 15:00:00', 'UTC')))
      AND positionCaseInsensitive(meta_client_name, '7870') > 0
      AND status = 'VALID'
      AND meta_execution_implementation != ''

    UNION ALL

    SELECT
        meta_execution_implementation AS el,
        'EL (snooper)' AS side,
        if(event_date_time >= toDateTime('2026-07-09 09:00:00', 'UTC')
           AND event_date_time < toDateTime('2026-07-09 11:00:00', 'UTC'), 'spike', 'baseline') AS period,
        duration_ms AS d
    FROM default.execution_engine_new_payload
    WHERE meta_network_name = 'mainnet'
      AND block_number >= 25490000 AND block_number <= 25500000
      AND ((event_date_time >= toDateTime('2026-07-09 09:00:00', 'UTC') AND event_date_time < toDateTime('2026-07-09 11:00:00', 'UTC'))
        OR (event_date_time >= toDateTime('2026-07-09 13:00:00', 'UTC') AND event_date_time < toDateTime('2026-07-09 15:00:00', 'UTC')))
      AND positionCaseInsensitive(meta_client_name, '7870') > 0
      AND status = 'VALID'
      AND meta_execution_implementation != ''
)
GROUP BY el, side, period
ORDER BY el, side, period
