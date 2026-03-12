SELECT
    multiIf(
        target_address = '0x0000000000000000000000000000000000000006', 'ecAdd',
        target_address = '0x0000000000000000000000000000000000000007', 'ecMul',
        target_address = '0x0000000000000000000000000000000000000008', 'ecPairing',
        'unknown'
    ) AS precompile,
    gas AS gas_value,
    count() AS call_count,
    round(count() * 100.0 / sum(count()) OVER (PARTITION BY precompile), 4) AS pct
FROM mainnet.int_transaction_call_frame FINAL
WHERE block_number BETWEEN 24120001 AND 24546241
    AND target_address IN (
        '0x0000000000000000000000000000000000000006',
        '0x0000000000000000000000000000000000000007',
        '0x0000000000000000000000000000000000000008'
    )
GROUP BY precompile, gas_value
ORDER BY precompile, call_count DESC
