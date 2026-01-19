SELECT
    toDate(slot_start_date_time) as date,
    count(*) as total_blocks,
    countIf(block_total_bytes > 0) as non_empty_blocks,
    round(avg(block_total_bytes) / 1024, 2) as avg_block_size_kb,
    round(avg(execution_payload_transactions_count), 1) as avg_txs_per_block
FROM canonical_beacon_block
WHERE slot_start_date_time >= now() - INTERVAL 7 DAY
  AND meta_network_name = 'mainnet'
GROUP BY date
ORDER BY date DESC
