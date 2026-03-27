-- Daily attestation inclusion delay distribution.
-- For each attested slot, how many slots later was the attestation included in a block?
-- Delay 1 = included in the very next block (the assumption used by the FCR simulator).
SELECT
    toDate(slot_start_date_time) AS day,
    block_slot - slot AS inclusion_delay,
    count() AS attestation_count
FROM canonical_beacon_elaborated_attestation
WHERE meta_network_name = 'mainnet'
    AND slot_start_date_time >= '2026-02-25'
    AND slot_start_date_time < '2026-03-25'
    AND block_slot >= slot
    AND block_slot - slot <= 5
GROUP BY day, inclusion_delay
ORDER BY day, inclusion_delay
