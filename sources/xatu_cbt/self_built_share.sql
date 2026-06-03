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
classified AS (
    SELECT if(bl.block_root IN (SELECT block_root FROM mev), 'relay', 'local') AS source
    FROM blocks bl
    INNER JOIN arrival a ON bl.block_root = a.block_root
)
SELECT
    toFloat64(count()) AS total_blocks,
    toFloat64(countIf(source = 'local')) AS local_blocks,
    toFloat64(countIf(source = 'relay')) AS relay_blocks,
    round(countIf(source = 'local') * 100.0 / count(), 1) AS pct_local,
    round(countIf(source = 'local') * 1.0 / count(), 4) AS pct_local_frac
FROM classified
