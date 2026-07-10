-- Gas consumed per block by transactions to the three XEN batch-mint contracts
-- CoinTool XEN Batch Minter, MCT XENFT, MCT-XEN Batch Minter
-- Fixed block range: 25493987 to 25494583 (2026-07-09 09:00 to 11:00 UTC)
SELECT
    toInt64(block_number) AS block_number,
    round(sum(gas_used) / 1e6, 1) AS actor_mgas,
    toFloat64(count()) AS actor_txs
FROM default.canonical_execution_transaction
WHERE meta_network_name = 'mainnet'
  AND block_number >= 25493987
  AND block_number <= 25494583
  AND to_address IN (
      '0x0de8bf93da2f7eecb3d9169422413a9bef4ef628',
      '0x0000000000771a79d0fc7f3b7fe270eb4498f20b',
      '0x2f848984984d6c3c036174ce627703edaf780479'
  )
GROUP BY block_number
ORDER BY block_number
