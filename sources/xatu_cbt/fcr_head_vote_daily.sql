-- Daily slot confirmation rates at multiple adversarial stake thresholds.
-- A slot is "confirmable" if votes_head / votes_max >= threshold.
-- Filters:
--   votes_max >= 29000: full committee data (excludes raw ingestion gaps)
--   (votes_head + votes_other) >= votes_max * 0.9: attestation data is complete
--   total_slots >= 5000: excludes days with too few qualifying slots
SELECT *
FROM (
    SELECT
        toDate(slot_start_date_time) as date,
        count() as total_slots,
        countIf(votes_head * 100.0 / votes_max >= 95) as confirmed_95,
        countIf(votes_head * 100.0 / votes_max >= 90) as confirmed_90,
        countIf(votes_head * 100.0 / votes_max >= 85) as confirmed_85,
        countIf(votes_head * 100.0 / votes_max >= 80) as confirmed_80,
        round(countIf(votes_head * 100.0 / votes_max >= 95) * 100.0 / count(), 2) as pct_95,
        round(countIf(votes_head * 100.0 / votes_max >= 90) * 100.0 / count(), 2) as pct_90,
        round(countIf(votes_head * 100.0 / votes_max >= 85) * 100.0 / count(), 2) as pct_85,
        round(countIf(votes_head * 100.0 / votes_max >= 80) * 100.0 / count(), 2) as pct_80
    FROM mainnet.fct_attestation_correctness_canonical
    WHERE slot_start_date_time >= '2025-11-07'
      AND slot_start_date_time < '2026-03-18'
      AND votes_max >= 29000
      AND (votes_head + votes_other) >= votes_max * 0.9
    GROUP BY date
)
WHERE total_slots >= 5000
ORDER BY date ASC
