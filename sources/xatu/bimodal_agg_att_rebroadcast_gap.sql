-- Propagation histogram (0-24s, 1s bins) split by novel vs rebroadcast
-- An observation is "rebroadcast" if the same message_id was first seen in an earlier 1s bin
-- 1-hour sample window for query efficiency
-- Fixed time window: 2026-02-05 12:00 to 13:00
WITH first_seen AS (
    SELECT
        message_id,
        intDiv(min(propagation_slot_start_diff), 1000) AS first_bin_s
    FROM default.libp2p_gossipsub_aggregate_and_proof
    WHERE meta_network_name = 'mainnet'
    AND slot_start_date_time >= '2026-02-05T12:00:00'
    AND slot_start_date_time < '2026-02-05T13:00:00'
    AND propagation_slot_start_diff BETWEEN 0 AND 24000
    GROUP BY message_id
)
SELECT
    intDiv(a.propagation_slot_start_diff, 1000) AS bin_s,
    countIf(intDiv(a.propagation_slot_start_diff, 1000) <= f.first_bin_s) AS novel_cnt,
    countIf(intDiv(a.propagation_slot_start_diff, 1000) > f.first_bin_s) AS rebroadcast_cnt
FROM default.libp2p_gossipsub_aggregate_and_proof a
GLOBAL INNER JOIN first_seen f ON a.message_id = f.message_id
WHERE a.meta_network_name = 'mainnet'
AND a.slot_start_date_time >= '2026-02-05T12:00:00'
AND a.slot_start_date_time < '2026-02-05T13:00:00'
AND a.propagation_slot_start_diff BETWEEN 0 AND 24000
GROUP BY bin_s
ORDER BY bin_s
