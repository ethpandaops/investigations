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
prop AS (
    SELECT slot, proposer_validator_index AS validator_index
    FROM mainnet.fct_block_proposer FINAL
    WHERE slot_start_date_time >= '2026-05-01' AND slot_start_date_time < '2026-06-01'
      AND status = 'canonical'
)
SELECT
    p.validator_index AS validator_index,
    if(bl.block_root IN (SELECT block_root FROM mev), 'relay', 'local') AS source,
    a.arr_ms AS arr_ms
FROM blocks bl
INNER JOIN arrival a ON bl.block_root = a.block_root
INNER JOIN prop p ON bl.slot = p.slot
