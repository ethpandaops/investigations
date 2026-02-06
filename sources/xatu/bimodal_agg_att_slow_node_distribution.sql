-- Classifies Prysm peers by how often they were caught behind on block processing
-- Shows both peer count and aggregate message volume per category
-- Uses outbound status checks during seconds 5-8 of each slot
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
peer_behind_rate AS (
    SELECT
        ss.peer_id_unique_key,
        count() AS total_slots,
        sum(is_behind) AS behind_slots,
        behind_slots * 100.0 / total_slots AS behind_pct
    FROM slot_status ss
    GLOBAL INNER JOIN prysm_peers pp ON ss.peer_id_unique_key = pp.peer_id
    GROUP BY ss.peer_id_unique_key
),
peer_messages AS (
    SELECT
        peer_id_unique_key AS peer_id,
        countIf(propagation_slot_start_diff BETWEEN 4000 AND 11000) AS peak_msgs,
        countIf(propagation_slot_start_diff BETWEEN 12000 AND 20000) AS tail_msgs
    FROM default.libp2p_gossipsub_aggregate_and_proof
    WHERE meta_network_name = 'mainnet'
    AND slot_start_date_time >= '2026-02-05T12:00:00' AND slot_start_date_time < '2026-02-05T12:15:00'
    AND propagation_slot_start_diff BETWEEN 4000 AND 20000
    GROUP BY peer_id
)
SELECT
    multiIf(
        pbr.behind_pct < 10, 'Rarely (<10%)',
        pbr.behind_pct < 40, 'Sometimes (10-40%)',
        pbr.behind_pct < 80, 'Often (40-80%)',
        'Always (>80%)'
    ) AS category,
    count() AS peer_count,
    round(avg(pbr.behind_pct), 1) AS avg_behind_pct,
    sum(coalesce(pm.peak_msgs, 0)) AS total_peak_msgs,
    sum(coalesce(pm.tail_msgs, 0)) AS total_tail_msgs,
    sum(coalesce(pm.peak_msgs, 0)) + sum(coalesce(pm.tail_msgs, 0)) AS total_msgs
FROM peer_behind_rate pbr
GLOBAL LEFT JOIN peer_messages pm ON pbr.peer_id_unique_key = pm.peer_id
GROUP BY category
ORDER BY
    CASE category
        WHEN 'Rarely (<10%)' THEN 0
        WHEN 'Sometimes (10-40%)' THEN 1
        WHEN 'Often (40-80%)' THEN 2
        ELSE 3
    END
