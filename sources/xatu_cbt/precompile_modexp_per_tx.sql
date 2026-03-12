SELECT
    modexp_count,
    count() AS tx_count,
    round(count() * 100.0 / sum(count()) OVER (), 2) AS pct
FROM (
    SELECT
        transaction_hash,
        count() AS modexp_count
    FROM mainnet.int_transaction_call_frame FINAL
    WHERE block_number BETWEEN 24540000 AND 24546241
        AND target_address = '0x0000000000000000000000000000000000000005'
    GROUP BY transaction_hash
)
GROUP BY modexp_count
ORDER BY tx_count DESC
LIMIT 20
