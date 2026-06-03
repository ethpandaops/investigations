WITH
blocks AS (
    SELECT slot, toString(block_root) AS block_root
    FROM mainnet.fct_block FINAL
    WHERE slot_start_date_time >= '2026-05-01' AND slot_start_date_time < '2026-06-01'
      AND status = 'canonical'
),
mev AS (
    SELECT DISTINCT toString(block_root) AS block_root
    FROM mainnet.fct_block_mev FINAL
    WHERE slot_start_date_time >= '2026-05-01' AND slot_start_date_time < '2026-06-01'
      AND status = 'canonical'
),
arrival AS (
    SELECT slot, toString(block_root) AS block_root, MIN(seen_slot_start_diff) AS arr_ms
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-05-01' AND slot_start_date_time < '2026-06-01'
    GROUP BY slot, block_root
),
ent AS (
    SELECT slot, COALESCE(entity, 'unknown') AS entity
    FROM mainnet.fct_block_proposer_entity FINAL
    WHERE slot_start_date_time >= '2026-05-01' AND slot_start_date_time < '2026-06-01'
),
classified AS (
    SELECT
        bl.slot AS slot,
        if(bl.block_root IN (SELECT block_root FROM mev), 'relay', 'local') AS source,
        a.arr_ms AS arr_ms
    FROM blocks bl
    INNER JOIN arrival a ON bl.block_root = a.block_root
)
SELECT
    e.entity AS entity,
    toFloat64(countIf(c.source = 'local')) AS local_blocks,
    toFloat64(countIf(c.source = 'relay')) AS relay_blocks,
    round(countIf(c.source = 'local') * 100.0 / count(), 1) AS pct_local,
    round(quantileIf(0.50)(c.arr_ms, c.source = 'local') / 1000.0, 3) AS local_p50_s,
    round(quantileIf(0.50)(c.arr_ms, c.source = 'relay') / 1000.0, 3) AS relay_p50_s
FROM classified c
INNER JOIN ent e ON c.slot = e.slot
GROUP BY entity
HAVING countIf(c.source = 'local') >= 100
ORDER BY local_p50_s ASC
