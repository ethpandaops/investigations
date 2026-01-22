-- Daily win rate for the high-peer TYSM node
-- Win = seeing a block first among all reporting nodes
WITH winners AS (
    SELECT
        toDate(slot_start_date_time) as day,
        slot,
        block_root,
        argMin(node_id, seen_slot_start_diff) AS first_node
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
    GROUP BY day, slot, block_root
)
SELECT
    day,
    countIf(first_node = 'utility-mainnet-prysm-geth-tysm-003') as wins,
    count(*) as total_blocks,
    round(countIf(first_node = 'utility-mainnet-prysm-geth-tysm-003') * 100.0 / count(*), 2) as win_rate_pct
FROM winners
GROUP BY day
ORDER BY day ASC
