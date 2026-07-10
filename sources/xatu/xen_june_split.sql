-- Replication check: same block-content split during the campaign's peak, three weeks earlier
-- Window: 2026-06-28 20:00-22:00 UTC (heaviest XEN hour of the campaign), utility 7870 nodes.
-- erigon is excluded: it was recovering from a resync that evening (multi-second medians on clean blocks).
SELECT
    meta_execution_implementation AS el,
    if(block_number GLOBAL IN (
        SELECT DISTINCT block_number
        FROM default.canonical_execution_transaction
        WHERE meta_network_name = 'mainnet'
          AND block_number >= 25405000 AND block_number <= 25420000
          AND to_address IN (
              '0x0de8bf93da2f7eecb3d9169422413a9bef4ef628',
              '0x0000000000771a79d0fc7f3b7fe270eb4498f20b',
              '0x2f848984984d6c3c036174ce627703edaf780479'
          )
    ), 'with_xen', 'clean') AS grp,
    toFloat64(count()) AS blocks,
    round(quantile(0.5)(duration_ms), 0) AS med_ms
FROM default.consensus_engine_api_new_payload
WHERE meta_network_name = 'mainnet'
  AND slot_start_date_time >= toDateTime('2026-06-28 20:00:00', 'UTC')
  AND slot_start_date_time < toDateTime('2026-06-28 22:00:00', 'UTC')
  AND positionCaseInsensitive(meta_client_name, 'utility-') > 0
  AND positionCaseInsensitive(meta_client_name, '7870') > 0
  AND status = 'VALID'
  AND meta_execution_implementation NOT IN ('', 'erigon')
GROUP BY el, grp
ORDER BY el, grp
