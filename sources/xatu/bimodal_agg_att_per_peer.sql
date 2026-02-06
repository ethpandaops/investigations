-- Per-peer tail percentage quantiles by client (for box plot)
-- For each relay peer, calculates what % of their forwarded aggregates land in the tail
-- Returns P5, Q1, median, Q3, P95 per client
-- Fixed time window: 2026-02-05 to 2026-02-06
WITH peers AS (
    SELECT DISTINCT
        remote_peer_id_unique_key AS peer_id,
        multiIf(
            remote_agent_implementation LIKE '%prysm%', 'Prysm',
            remote_agent_implementation LIKE '%lighthouse%', 'Lighthouse',
            remote_agent_implementation LIKE '%teku%', 'Teku',
            remote_agent_implementation LIKE '%erigon%', 'Erigon',
            remote_agent_implementation LIKE '%nimbus%', 'Nimbus',
            remote_agent_implementation LIKE '%lodestar%', 'Lodestar',
            remote_agent_implementation LIKE '%grandine%', 'Grandine',
            'Unknown'
        ) AS client
    FROM default.libp2p_synthetic_heartbeat
    WHERE meta_network_name = 'mainnet'
    AND event_date_time >= '2026-02-05' AND event_date_time < '2026-02-06'
),
per_peer AS (
    SELECT
        p.client,
        a.peer_id_unique_key AS peer_id,
        countIf(a.propagation_slot_start_diff BETWEEN 4000 AND 11000) AS peak_cnt,
        countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000) AS tail_cnt,
        countIf(a.propagation_slot_start_diff BETWEEN 4000 AND 11000)
            + countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000) AS total_cnt,
        round(countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000)
            * 100.0
            / (countIf(a.propagation_slot_start_diff BETWEEN 4000 AND 11000)
               + countIf(a.propagation_slot_start_diff BETWEEN 12000 AND 20000)), 1) AS tail_pct
    FROM default.libp2p_gossipsub_aggregate_and_proof a
    GLOBAL INNER JOIN peers p ON a.peer_id_unique_key = p.peer_id
    WHERE a.meta_network_name = 'mainnet'
    AND a.slot_start_date_time >= '2026-02-05T00:00:00'
    AND a.slot_start_date_time < '2026-02-06T00:00:00'
    AND a.propagation_slot_start_diff BETWEEN 4000 AND 20000
    GROUP BY p.client, peer_id
    HAVING total_cnt >= 100
)
SELECT
    client,
    count() AS peer_count,
    round(quantile(0.05)(tail_pct), 1) AS p5,
    round(quantile(0.25)(tail_pct), 1) AS q1,
    round(quantile(0.5)(tail_pct), 1) AS median,
    round(quantile(0.75)(tail_pct), 1) AS q3,
    round(quantile(0.95)(tail_pct), 1) AS p95
FROM per_peer
WHERE client NOT IN ('Unknown')
GROUP BY client
ORDER BY median DESC
