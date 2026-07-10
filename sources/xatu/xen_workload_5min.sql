-- Block workload per 5-minute bucket (one row per unique block), incident window
-- Fixed window: 2026-07-09 08:00 to 12:00 UTC
SELECT
    formatDateTime(toStartOfFiveMinutes(t0), '%H:%M') AS bucket_label,
    toStartOfFiveMinutes(t0) AS bucket,
    round(avg(g) / 1e6, 1) AS avg_mgas,
    round(max(g) / 1e6, 1) AS max_mgas,
    round(avg(txc), 0) AS avg_tx,
    round(avg(bc), 1) AS avg_blobs,
    toFloat64(count()) AS blocks
FROM (
    SELECT
        block_hash,
        any(gas_used) AS g,
        any(tx_count) AS txc,
        any(blob_count) AS bc,
        any(slot_start_date_time) AS t0
    FROM default.consensus_engine_api_new_payload
    WHERE meta_network_name = 'mainnet'
      AND slot_start_date_time >= toDateTime('2026-07-09 08:00:00', 'UTC')
      AND slot_start_date_time < toDateTime('2026-07-09 12:00:00', 'UTC')
      AND positionCaseInsensitive(meta_client_name, '7870') > 0
    GROUP BY block_hash
)
GROUP BY bucket
ORDER BY bucket
