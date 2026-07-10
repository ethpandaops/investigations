-- Daily gas consumed by the three XEN batch-mint contracts over the past ~2 weeks
-- Fixed block range 25394000-25500000 (~2026-06-25 to 2026-07-10). Dates approximated
-- from block numbers at 12s/block anchored to block 25491287 = 2026-07-09 00:00 UTC.
SELECT
    toDate(toDateTime('2026-07-09 00:00:00', 'UTC') + toIntervalSecond((toInt64(block_number) - 25491287) * 12)) AS approx_date,
    toFloat64(count()) AS txs,
    round(sum(gas_used) / 1e9, 2) AS ggas
FROM default.canonical_execution_transaction
WHERE meta_network_name = 'mainnet'
  AND block_number >= 25394000 AND block_number < 25500000
  AND to_address IN (
      '0x0de8bf93da2f7eecb3d9169422413a9bef4ef628',
      '0x0000000000771a79d0fc7f3b7fe270eb4498f20b',
      '0x2f848984984d6c3c036174ce627703edaf780479'
  )
GROUP BY approx_date
ORDER BY approx_date
