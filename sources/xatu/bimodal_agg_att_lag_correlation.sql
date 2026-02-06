-- Per-slot peer behavior: does catching a Prysm peer behind on block processing
-- predict what they forward to us?
-- Classifies Prysm peer+slot pairs by block state (behind vs had block) based on
-- outbound libp2p_handle_status during seconds 5-8 of each slot, then checks
-- which aggregates they forwarded
-- Fixed time window: 2026-02-05 12:00:00 to 2026-02-05 12:15:00 (15-min sample)
WITH
slot_status AS (
    SELECT
        peer_id_unique_key,
        intDiv(toUnixTimestamp(event_date_time) - 1606824023, 12) AS slot_num,
        max(toUInt8(response_head_slot < request_head_slot)) AS is_behind
    FROM default.libp2p_handle_status
    WHERE meta_network_name = 'mainnet'
    AND event_date_time >= '2026-02-05 12:00:00' AND event_date_time < '2026-02-05 12:15:00'
    AND direction = 'outbound'
    AND response_head_slot IS NOT NULL
    AND request_head_slot IS NOT NULL
    AND (toUnixTimestamp(event_date_time) - 1606824023) % 12 BETWEEN 5 AND 8
    GROUP BY peer_id_unique_key, slot_num
),
prysm_peers AS (
    SELECT DISTINCT remote_peer_id_unique_key AS peer_id
    FROM default.libp2p_synthetic_heartbeat
    WHERE meta_network_name = 'mainnet'
    AND event_date_time >= '2026-02-05 12:00:00' AND event_date_time < '2026-02-05 12:15:00'
    AND remote_agent_implementation LIKE '%prysm%'
),
peer_aggs AS (
    SELECT
        peer_id_unique_key AS peer_id,
        intDiv(toUnixTimestamp(slot_start_date_time) - 1606824023, 12) AS slot_num,
        countIf(propagation_slot_start_diff BETWEEN 4000 AND 11000) AS peak_cnt,
        countIf(propagation_slot_start_diff BETWEEN 12000 AND 20000) AS tail_cnt
    FROM default.libp2p_gossipsub_aggregate_and_proof
    WHERE meta_network_name = 'mainnet'
    AND slot_start_date_time >= '2026-02-05T12:00:00' AND slot_start_date_time < '2026-02-05T12:15:00'
    AND propagation_slot_start_diff BETWEEN 4000 AND 20000
    GROUP BY peer_id, slot_num
),
combined AS (
    SELECT
        if(ss.is_behind = 1, 'Caught behind', 'Had block') AS state,
        multiIf(
            pa.peer_id IS NULL OR (pa.peak_cnt = 0 AND pa.tail_cnt = 0), 'Sent nothing',
            pa.peak_cnt > 0 AND pa.tail_cnt = 0, 'Only peak',
            pa.peak_cnt > 0 AND pa.tail_cnt > 0, 'Peak and tail',
            'Only tail'
        ) AS behavior
    FROM slot_status ss
    GLOBAL INNER JOIN prysm_peers pp ON ss.peer_id_unique_key = pp.peer_id
    GLOBAL LEFT JOIN peer_aggs pa ON ss.peer_id_unique_key = pa.peer_id AND ss.slot_num = pa.slot_num
)
SELECT
    state,
    behavior,
    count() AS cnt,
    round(count() * 100.0 / sum(count()) OVER (PARTITION BY state), 1) AS pct
FROM combined
GROUP BY state, behavior
ORDER BY
    CASE state WHEN 'Had block' THEN 0 ELSE 1 END,
    CASE behavior WHEN 'Sent nothing' THEN 0 WHEN 'Only peak' THEN 1 WHEN 'Peak and tail' THEN 2 ELSE 3 END
