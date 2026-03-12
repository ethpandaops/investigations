SELECT
    parent.target_address AS calling_contract,
    count() AS total_calls,
    sum(child.gas) AS total_gas,
    round(avg(child.gas), 0) AS avg_gas,
    min(child.gas) AS min_gas,
    max(child.gas) AS max_gas
FROM mainnet.int_transaction_call_frame AS child FINAL
JOIN mainnet.int_transaction_call_frame AS parent FINAL
    ON child.block_number = parent.block_number
    AND child.transaction_hash = parent.transaction_hash
    AND child.parent_call_frame_id = parent.call_frame_id
WHERE child.block_number BETWEEN 24540000 AND 24546241
    AND child.target_address = '0x0000000000000000000000000000000000000001'
    AND child.opcode_count = 0
    AND child.gas > 0
    AND child.depth > 0
GROUP BY calling_contract
ORDER BY total_calls DESC
LIMIT 15
