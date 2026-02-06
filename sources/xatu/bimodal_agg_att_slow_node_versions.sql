-- Aggregate message volume by Prysm version - peak vs tail
-- Shows which versions are responsible for the most tail traffic
-- Fixed time window: 2026-02-05 12:00:00 to 2026-02-05 12:15:00 (15-min sample)
WITH
prysm_peer_versions AS (
    SELECT
        remote_peer_id_unique_key AS peer_id,
        any(remote_agent_version) AS version
    FROM default.libp2p_synthetic_heartbeat
    WHERE meta_network_name = 'mainnet'
    AND event_date_time >= '2026-02-05 12:00:00' AND event_date_time < '2026-02-05 12:15:00'
    AND remote_agent_implementation LIKE '%prysm%'
    GROUP BY peer_id
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
    pv.version,
    count(DISTINCT pv.peer_id) AS peer_count,
    sum(coalesce(pm.peak_msgs, 0)) AS peak_msgs,
    sum(coalesce(pm.tail_msgs, 0)) AS tail_msgs,
    sum(coalesce(pm.peak_msgs, 0)) + sum(coalesce(pm.tail_msgs, 0)) AS total_msgs,
    round(sum(coalesce(pm.tail_msgs, 0)) * 100.0 /
        nullIf(sum(coalesce(pm.peak_msgs, 0)) + sum(coalesce(pm.tail_msgs, 0)), 0), 1) AS tail_pct
FROM prysm_peer_versions pv
GLOBAL LEFT JOIN peer_messages pm ON pv.peer_id = pm.peer_id
GROUP BY pv.version
HAVING total_msgs >= 1000
ORDER BY total_msgs DESC
