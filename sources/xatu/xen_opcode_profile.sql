-- Opcode profile of the 30 largest CoinTool XEN batch-mint transactions, from execution traces
-- Fixed block range 25396821-25399520 (earlier campaign activity already covered by the structlog pipeline)
SELECT
    operation,
    toFloat64(sum(opcode_count)) AS op_count,
    round(sum(gas) / 1e6, 2) AS mgas_self,
    toFloat64(sum(cold_access_count)) AS cold_accesses
FROM default.canonical_execution_transaction_structlog_agg
WHERE meta_network_name = 'mainnet'
  AND block_number >= 25396821 AND block_number <= 25399520
  AND operation != ''
  AND transaction_hash GLOBAL IN (
      SELECT transaction_hash
      FROM default.canonical_execution_transaction
      WHERE meta_network_name = 'mainnet'
        AND block_number >= 25396821 AND block_number <= 25399520
        AND to_address = '0x0de8bf93da2f7eecb3d9169422413a9bef4ef628'
      ORDER BY gas_used DESC, transaction_hash
      LIMIT 30
  )
GROUP BY operation
ORDER BY mgas_self DESC
LIMIT 15
