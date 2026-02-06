-- Aggregate attestation propagation times in 250ms bins
-- Shows the bimodal distribution: main peak at ~8s, second peak at ~14-16s
-- Fixed time window: 2026-02-05 to 2026-02-06
SELECT
    floor(propagation_slot_start_diff / 250) * 250 AS bin_ms,
    count(*) AS cnt
FROM default.libp2p_gossipsub_aggregate_and_proof
WHERE meta_network_name = 'mainnet'
AND slot_start_date_time >= '2026-02-05T00:00:00'
AND slot_start_date_time < '2026-02-06T00:00:00'
AND propagation_slot_start_diff BETWEEN 4000 AND 22000
GROUP BY bin_ms
ORDER BY bin_ms ASC
