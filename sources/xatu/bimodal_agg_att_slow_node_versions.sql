-- Behind rate by Prysm version - shows which versions have the most stuck peers
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
peer_behind AS (
    SELECT
        ss.peer_id_unique_key AS peer_id,
        max(ss.is_behind) AS ever_behind
    FROM slot_status ss
    GLOBAL INNER JOIN prysm_peer_versions pv ON ss.peer_id_unique_key = pv.peer_id
    GROUP BY ss.peer_id_unique_key
)
SELECT
    pv.version,
    count(DISTINCT pv.peer_id) AS total_peers,
    countIf(pb.ever_behind = 1) AS behind_peers,
    round(countIf(pb.ever_behind = 1) * 100.0 / count(DISTINCT pv.peer_id), 1) AS behind_pct
FROM prysm_peer_versions pv
GLOBAL LEFT JOIN peer_behind pb ON pv.peer_id = pb.peer_id
GROUP BY pv.version
HAVING total_peers >= 20
ORDER BY behind_pct DESC
