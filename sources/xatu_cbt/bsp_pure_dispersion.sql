-- Pure mesh dispersion: per-(slot, individual-class node), how long after the
-- first network sighting did this node see the block? This isolates gossip mesh
-- spread from builder release timing.
WITH first_seen AS (
    SELECT slot, block_root, MIN(seen_slot_start_diff) AS t_first
    FROM mainnet.fct_block_first_seen_by_node FINAL
    WHERE slot_start_date_time >= '2026-04-25 00:00:00'
      AND slot_start_date_time <  '2026-05-02 00:00:00'
      AND seen_slot_start_diff < 12000
    GROUP BY slot, block_root
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
        b.post_b / 1024 AS post_kb
    FROM seen AS s
    INNER JOIN first_seen AS fs ON s.slot = fs.slot AND s.block_root = fs.block_root
    INNER JOIN blocks AS b ON s.slot = b.slot AND s.block_root = b.block_root
    WHERE s.seen_slot_start_diff - fs.t_first > 0
)
SELECT
    multiIf(
        post_kb < 16, '00. <16 KB',
        post_kb < 32, '01. 16-32 KB',
        post_kb < 48, '02. 32-48 KB',
        post_kb < 64, '03. 48-64 KB',
        post_kb < 80, '04. 64-80 KB',
        post_kb < 96, '05. 80-96 KB',
        post_kb < 112, '06. 96-112 KB',
        post_kb < 128, '07. 112-128 KB',
        post_kb < 144, '08. 128-144 KB',
        post_kb < 160, '09. 144-160 KB',
        post_kb < 192, '10. 160-192 KB',
        post_kb < 224, '11. 192-224 KB',
        '12. 224+ KB'
    ) AS bin_label,
    round(avg(post_kb), 0) AS bin_mid_kb,
    count() AS observations,
    round(quantile(0.5)(dispersion_ms),  0) AS p50_disp_ms,
    round(quantile(0.75)(dispersion_ms), 0) AS p75_disp_ms,
    round(quantile(0.95)(dispersion_ms), 0) AS p95_disp_ms,
    round(quantile(0.99)(dispersion_ms), 0) AS p99_disp_ms
FROM joined
GROUP BY bin_label
HAVING observations >= 1000
ORDER BY bin_label ASC
