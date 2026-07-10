-- 5-minute p50 engine_newPayload duration per EL client, utility cluster 7870 nodes
-- Fixed window: 2026-07-09 08:00 to 12:00 UTC (the incident window)
SELECT
    formatDateTime(toStartOfFiveMinutes(slot_start_date_time), '%H:%M') AS bucket_label,
    toStartOfFiveMinutes(slot_start_date_time) AS bucket,
    meta_execution_implementation AS el,
    round(quantile(0.5)(duration_ms), 1) AS p50_ms
FROM default.consensus_engine_api_new_payload
WHERE meta_network_name = 'mainnet'
  AND slot_start_date_time >= toDateTime('2026-07-09 08:00:00', 'UTC')
  AND slot_start_date_time < toDateTime('2026-07-09 12:00:00', 'UTC')
  AND positionCaseInsensitive(meta_client_name, 'utility-') > 0
  AND positionCaseInsensitive(meta_client_name, '7870') > 0
  AND status = 'VALID'
  AND meta_execution_implementation != ''
GROUP BY bucket, el
ORDER BY bucket, el
