-- Wide-format lookup: per post-snappy size bin, MEV-Boost and Local
-- dispersion percentiles in the same row. Rendered as two separate
-- tables in the page (one per source) by filtering columns in Svelte.
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
    SELECT slot, block_root, block_total_bytes_compressed AS post_b
    FROM mainnet.fct_block_head FINAL
    WHERE slot_start_date_time >= '2026-04-25 00:00:00'
      AND slot_start_date_time <  '2026-05-02 00:00:00'
      AND block_total_bytes_compressed IS NOT NULL
),
seen AS (
    SELECT slot, block_root, seen_slot_start_diff
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-04-25 00:00:00'
      AND slot_start_date_time <  '2026-05-02 00:00:00'
      AND seen_slot_start_diff < 12000
      AND classification = 'individual'
),
joined AS (
    SELECT
        s.seen_slot_start_diff - fs.t_first AS dispersion_ms,
        b.post_b / 1024 AS post_kb,
        if((s.slot, s.block_root) IN (SELECT slot, block_root FROM mev_blocks), 'mev', 'local') AS source
    FROM seen AS s
    INNER JOIN first_seen AS fs ON s.slot = fs.slot AND s.block_root = fs.block_root
    INNER JOIN blocks AS b ON s.slot = b.slot AND s.block_root = b.block_root
    WHERE s.seen_slot_start_diff - fs.t_first > 0
)
SELECT
    multiIf(
        post_kb < 16,  '< 16 KB',
        post_kb < 32,  '16 - 32 KB',
        post_kb < 48,  '32 - 48 KB',
        post_kb < 64,  '48 - 64 KB',
        post_kb < 80,  '64 - 80 KB',
        post_kb < 96,  '80 - 96 KB',
        post_kb < 112, '96 - 112 KB',
        post_kb < 128, '112 - 128 KB',
        post_kb < 144, '128 - 144 KB',
        post_kb < 160, '144 - 160 KB',
        post_kb < 192, '160 - 192 KB',
        post_kb < 224, '192 - 224 KB',
        '224+ KB'
    ) AS size_bin,
    multiIf(
        post_kb < 16, 0, post_kb < 32, 16, post_kb < 48, 32, post_kb < 64, 48,
        post_kb < 80, 64, post_kb < 96, 80, post_kb < 112, 96, post_kb < 128, 112,
        post_kb < 144, 128, post_kb < 160, 144, post_kb < 192, 160, post_kb < 224, 192,
        224
    ) AS sort_key,
    countIf(source = 'mev')   AS mev_n,
    countIf(source = 'local') AS local_n,
    round(quantileIf(0.5)(dispersion_ms,  source = 'mev'),   0) AS mev_p50,
    round(quantileIf(0.75)(dispersion_ms, source = 'mev'),   0) AS mev_p75,
    round(quantileIf(0.95)(dispersion_ms, source = 'mev'),   0) AS mev_p95,
    round(quantileIf(0.99)(dispersion_ms, source = 'mev'),   0) AS mev_p99,
    round(quantileIf(0.5)(dispersion_ms,  source = 'local'), 0) AS local_p50,
    round(quantileIf(0.75)(dispersion_ms, source = 'local'), 0) AS local_p75,
    round(quantileIf(0.95)(dispersion_ms, source = 'local'), 0) AS local_p95,
    round(quantileIf(0.99)(dispersion_ms, source = 'local'), 0) AS local_p99
FROM joined
GROUP BY size_bin, sort_key
HAVING mev_n + local_n >= 200
ORDER BY sort_key ASC
