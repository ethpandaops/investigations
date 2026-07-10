-- Gas-normalized newPayload throughput per EL client: spike window vs quiet baseline
-- Spike: 2026-07-09 09:00-11:00 UTC. Baseline: 2026-07-09 13:00-15:00 UTC.
-- utility + sigma 7870 nodes, VALID responses only
SELECT
    meta_execution_implementation AS el,
    if(slot_start_date_time >= toDateTime('2026-07-09 09:00:00', 'UTC')
       AND slot_start_date_time < toDateTime('2026-07-09 11:00:00', 'UTC'), 'spike', 'baseline') AS period,
    toFloat64(count()) AS calls,
    round(quantile(0.5)(duration_ms), 1) AS p50_ms,
    round(quantile(0.95)(duration_ms), 1) AS p95_ms,
    round(avg(gas_used) / 1e6, 2) AS avg_mgas,
    round(quantile(0.5)(gas_used / greatest(duration_ms, 1) / 1000), 0) AS p50_mgas_per_s
FROM default.consensus_engine_api_new_payload
WHERE meta_network_name = 'mainnet'
  AND ((slot_start_date_time >= toDateTime('2026-07-09 09:00:00', 'UTC') AND slot_start_date_time < toDateTime('2026-07-09 11:00:00', 'UTC'))
    OR (slot_start_date_time >= toDateTime('2026-07-09 13:00:00', 'UTC') AND slot_start_date_time < toDateTime('2026-07-09 15:00:00', 'UTC')))
  AND (positionCaseInsensitive(meta_client_name, 'utility-') > 0 OR positionCaseInsensitive(meta_client_name, 'sigma-') > 0)
  AND positionCaseInsensitive(meta_client_name, '7870') > 0
  AND status = 'VALID'
  AND meta_execution_implementation != ''
GROUP BY el, period
ORDER BY el, period
