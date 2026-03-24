-- Daily reorg counts by depth
SELECT
    day_start_date as date,
    depth,
    reorg_count
FROM mainnet.fct_reorg_daily
WHERE day_start_date >= '2025-06-01'
  AND day_start_date < '2026-03-18'
  AND depth <= 5
ORDER BY day_start_date ASC, depth ASC
