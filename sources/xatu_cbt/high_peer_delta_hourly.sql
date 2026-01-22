-- Daily delta from network median (per-block comparison)
-- Negative = our node was faster, Positive = our node was slower
WITH block_timings AS (
    SELECT
        toDate(slot_start_date_time) as day,
        slot,
        block_root,
        minIf(seen_slot_start_diff, node_id = 'utility-mainnet-prysm-geth-tysm-003') as our_time,
        median(seen_slot_start_diff) as median_time
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
    GROUP BY day, slot, block_root
    HAVING our_time > 0
)
SELECT
    day,
    round(avg(our_time - median_time)) as "Delta from Median"
FROM block_timings
GROUP BY day
ORDER BY day ASC
