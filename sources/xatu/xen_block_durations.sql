-- Per-block newPayload duration for each EL client (utility cluster 7870 nodes), spike window
-- Fixed window: 2026-07-09 09:00 to 11:00 UTC
SELECT
    toInt64(block_number) AS block_number,
    round(any(gas_used) / 1e6, 1) AS mgas,
    toFloat64(any(blob_count)) AS blobs,
    toFloat64(maxIf(duration_ms, meta_execution_implementation = 'go-ethereum')) AS geth_ms,
    toFloat64(maxIf(duration_ms, meta_execution_implementation = 'Nethermind')) AS nethermind_ms,
    toFloat64(maxIf(duration_ms, meta_execution_implementation = 'Reth')) AS reth_ms,
    toFloat64(maxIf(duration_ms, meta_execution_implementation = 'ethrex')) AS ethrex_ms,
    toFloat64(maxIf(duration_ms, meta_execution_implementation = 'Besu')) AS besu_ms,
    toFloat64(maxIf(duration_ms, meta_execution_implementation = 'erigon')) AS erigon_ms
FROM default.consensus_engine_api_new_payload
WHERE meta_network_name = 'mainnet'
  AND slot_start_date_time >= toDateTime('2026-07-09 09:00:00', 'UTC')
  AND slot_start_date_time < toDateTime('2026-07-09 11:00:00', 'UTC')
  AND positionCaseInsensitive(meta_client_name, 'utility-') > 0
  AND positionCaseInsensitive(meta_client_name, '7870') > 0
  AND status = 'VALID'
GROUP BY block_number
ORDER BY block_number
