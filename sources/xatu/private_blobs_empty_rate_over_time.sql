-- Empty rate over time (hourly)
-- Shows how getBlobs EMPTY rate varies throughout the day
-- Fixed time window: 2026-01-17 to 2026-01-21
SELECT
    formatDateTime(toStartOfHour(slot_start_date_time), '%m-%d %H:00') as hour,
    round(countIf(status = 'EMPTY') * 100.0 / count(), 1) as empty_rate,
    round(countIf(status = 'SUCCESS') * 100.0 / count(), 1) as success_rate,
    count() as observations
FROM consensus_engine_api_get_blobs
WHERE meta_network_name = 'mainnet'
  AND slot_start_date_time >= '2026-01-17 00:00:00'
  AND slot_start_date_time < '2026-01-21 00:00:00'
  AND requested_count > 0
  AND status IN ('SUCCESS', 'EMPTY')
GROUP BY hour
ORDER BY hour
