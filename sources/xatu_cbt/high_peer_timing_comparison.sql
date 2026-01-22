-- Timing comparison: high-peer node vs network statistics
WITH block_stats AS (
    SELECT
        slot,
        block_root,
        min(seen_slot_start_diff) as network_fastest,
        median(seen_slot_start_diff) as network_median,
        avg(seen_slot_start_diff) as network_mean,
        minIf(seen_slot_start_diff, node_id = 'utility-mainnet-prysm-geth-tysm-003') as our_time
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
    GROUP BY slot, block_root
    HAVING our_time > 0
)
SELECT 'High-Peer Node Average' as metric, round(avg(our_time)) as value_ms FROM block_stats
UNION ALL
SELECT 'Network Fastest' as metric, round(avg(network_fastest)) as value_ms FROM block_stats
UNION ALL
SELECT 'Network Median' as metric, round(avg(network_median)) as value_ms FROM block_stats
UNION ALL
SELECT 'Network Mean' as metric, round(avg(network_mean)) as value_ms FROM block_stats
UNION ALL
SELECT 'Diff vs Median (negative = faster)' as metric, round(avg(our_time - network_median)) as value_ms FROM block_stats
UNION ALL
SELECT 'Diff vs Fastest' as metric, round(avg(our_time - network_fastest)) as value_ms FROM block_stats
ORDER BY metric
