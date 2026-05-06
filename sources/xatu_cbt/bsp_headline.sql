-- Headline numbers: per-source counts, t_first central tendency, typical block size.
WITH first_seen AS (
    SELECT slot, block_root, MIN(seen_slot_start_diff) AS t_first
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-04-25 00:00:00'
      AND slot_start_date_time <  '2026-05-02 00:00:00'
      AND seen_slot_start_diff < 12000
    GROUP BY slot, block_root
),
mev_blocks AS (
    SELECT DISTINCT slot, block_root
    FROM mainnet.fct_block_mev FINAL
    WHERE slot_start_date_time >= '2026-04-25 00:00:00'
      AND slot_start_date_time <  '2026-05-02 00:00:00'
),
blocks AS (
    SELECT
        slot, block_root,
        block_total_bytes AS pre_b,
        block_total_bytes_compressed AS post_b,
        execution_payload_gas_used AS gas
    FROM mainnet.fct_block_head FINAL
    WHERE slot_start_date_time >= '2026-04-25 00:00:00'
      AND slot_start_date_time <  '2026-05-02 00:00:00'
)
SELECT
    if((b.slot, b.block_root) IN (SELECT slot, block_root FROM mev_blocks),
       'MEV-Boost', 'Local') AS source,
    count() AS blocks,
    round(quantile(0.5)(b.pre_b)  / 1024, 0) AS p50_pre_kb,
    round(quantile(0.5)(b.post_b) / 1024, 0) AS p50_post_kb,
    round(quantile(0.95)(b.pre_b) / 1024, 0) AS p95_pre_kb,
    round(quantile(0.5)(b.gas) / 1e6, 1) AS p50_gas_M,
    round(quantile(0.5)(fs.t_first), 0)  AS p50_t_first_ms,
    round(quantile(0.95)(fs.t_first), 0) AS p95_t_first_ms
FROM blocks AS b
INNER JOIN first_seen AS fs ON b.slot = fs.slot AND b.block_root = fs.block_root
GROUP BY source
ORDER BY source ASC
