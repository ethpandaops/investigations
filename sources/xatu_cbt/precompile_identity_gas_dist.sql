SELECT
    gas AS gas_value,
    count() AS call_count,
    round(count() * 100.0 / sum(count()) OVER (), 4) AS pct
FROM mainnet.int_transaction_call_frame FINAL
WHERE block_number BETWEEN 24120001 AND 24546241
    AND target_address = '0x0000000000000000000000000000000000000004'
GROUP BY gas_value
ORDER BY call_count DESC
LIMIT 20
