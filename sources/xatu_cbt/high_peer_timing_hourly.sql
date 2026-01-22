-- Daily timing comparison: our node vs network median and fastest
-- Compare on a per-block basis to get accurate comparison
WITH block_timings AS (
    SELECT
        toDate(slot_start_date_time) as day,
        slot,
        block_root,
        minIf(seen_slot_start_diff, node_id = 'utility-mainnet-prysm-geth-tysm-003') as our_time,
        median(seen_slot_start_diff) as median_time,
        min(seen_slot_start_diff) as fastest_time
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
    GROUP BY day, slot, block_root
    HAVING our_time > 0
)
SELECT
    day,
    round(avg(our_time)) as "Our Node",
    round(avg(median_time)) as "Network Median",
    round(avg(fastest_time)) as "Network Fastest"
FROM block_timings
GROUP BY day
ORDER BY day ASC
