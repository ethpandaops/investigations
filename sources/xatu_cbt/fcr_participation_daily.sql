-- Daily attestation participation rate
SELECT
    day_start_date as date,
    slot_count,
    round(avg_participation_rate, 2) as avg_participation_rate,
    round(p50_participation_rate, 2) as p50_participation_rate,
    round(p05_participation_rate, 2) as p05_participation_rate,
    round(min_participation_rate, 2) as min_participation_rate
FROM mainnet.fct_attestation_participation_rate_daily
WHERE day_start_date >= '2025-06-01'
  AND day_start_date < '2026-03-18'
ORDER BY day_start_date ASC
