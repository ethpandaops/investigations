-- Daily win rate for the high-peer TYSM node with competing node count
WITH base AS (
    SELECT
        toDate(slot_start_date_time) as day,
        slot,
        block_root,
        node_id,
        seen_slot_start_diff
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-01-14'
      AND slot_start_date_time < '2026-01-21'
      AND seen_slot_start_diff <= 12000
),
winners AS (
    SELECT
        day,
        slot,
        block_root,
        argMin(node_id, seen_slot_start_diff) AS first_node
    FROM base
    GROUP BY day, slot, block_root
),
daily_stats AS (
    SELECT
        day,
        COUNT(DISTINCT node_id) as competing_nodes
    FROM base
    GROUP BY day
)
SELECT
    w.day,
    countIf(w.first_node = 'utility-mainnet-prysm-geth-tysm-003') as wins,
    count(*) as total_blocks,
    round(countIf(w.first_node = 'utility-mainnet-prysm-geth-tysm-003') * 100.0 / count(*), 2) as win_rate_pct,
    any(d.competing_nodes) as competing_nodes
FROM winners w
INNER JOIN daily_stats d ON w.day = d.day
GROUP BY w.day
ORDER BY w.day ASC
