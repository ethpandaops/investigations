-- Hourly p50 engine_newPayload duration per (cluster, EL client) across the EIP-7870 fleet
-- Fixed window: 2026-07-08 00:00 to 2026-07-10 00:00 UTC
SELECT
    formatDateTime(toStartOfHour(slot_start_date_time), '%m-%d %H:00') AS hour_label,
    toStartOfHour(slot_start_date_time) AS hour,
    splitByChar('-', splitByChar('/', meta_client_name)[3])[1] AS cluster,
    meta_execution_implementation AS el,
    round(quantile(0.5)(duration_ms), 1) AS p50_ms
FROM default.consensus_engine_api_new_payload
WHERE meta_network_name = 'mainnet'
  AND slot_start_date_time >= toDateTime('2026-07-08 00:00:00', 'UTC')
  AND slot_start_date_time < toDateTime('2026-07-10 00:00:00', 'UTC')
  AND positionCaseInsensitive(meta_client_name, '7870') > 0
  AND status = 'VALID'
  AND meta_execution_implementation != ''
GROUP BY hour, cluster, el
ORDER BY hour, cluster, el
