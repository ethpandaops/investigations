-- Per-client breakdown of peak vs tail aggregate attestation observations
-- Joins with heartbeat data to identify relay peer client type
-- Fixed time window: 2026-02-05 to 2026-02-06
WITH peers AS (
    SELECT DISTINCT
        remote_peer_id_unique_key AS peer_id,
        multiIf(
            remote_agent_implementation LIKE '%prysm%', 'Prysm',
            remote_agent_implementation LIKE '%lighthouse%', 'Lighthouse',
            remote_agent_implementation LIKE '%erigon%', 'Erigon',
            remote_agent_implementation LIKE '%teku%', 'Teku',
            remote_agent_implementation LIKE '%nimbus%', 'Nimbus',
            remote_agent_implementation LIKE '%lodestar%', 'Lodestar',
            remote_agent_implementation LIKE '%grandine%', 'Grandine',
            'Unknown'
        ) AS client
    FROM default.libp2p_synthetic_heartbeat
    WHERE meta_network_name = 'mainnet'
    AND event_date_time >= '2026-02-05' AND event_date_time < '2026-02-06'
)
SELECT
    COALESCE(NULLIF(p.client, ''), 'Unknown') AS client,
    countIf(a.propagation_slot_start_diff BETWEEN 4000 AND 11000) AS peak_cnt,
    countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000) AS tail_cnt,
    countIf(a.propagation_slot_start_diff BETWEEN 4000 AND 11000)
        + countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000) AS total_cnt,
    round(
        countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000)
        / (countIf(a.propagation_slot_start_diff BETWEEN 4000 AND 11000)
           + countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000))
        * 100, 1
    ) AS tail_pct
FROM default.libp2p_gossipsub_aggregate_and_proof a
GLOBAL LEFT JOIN peers p ON a.peer_id_unique_key = p.peer_id
WHERE a.meta_network_name = 'mainnet'
AND a.slot_start_date_time >= '2026-02-05T00:00:00'
AND a.slot_start_date_time < '2026-02-06T00:00:00'
AND a.propagation_slot_start_diff BETWEEN 4000 AND 20000
GROUP BY client
ORDER BY tail_pct DESC
