-- Sentry coverage per consensus client on glamsterdam-devnet-6: node count,
-- observed versions (last two days of the window), and first/last head event.
-- Fixed window: 2026-06-25 (devnet-6 genesis) to 2026-07-09 23:59:59 UTC.
SELECT
    h.impl AS impl,
    h.nodes AS nodes,
    h.first_seen AS first_seen,
    h.last_seen AS last_seen,
    v.versions AS versions
FROM (
    SELECT
        meta_consensus_implementation AS impl,
        toFloat64(uniqExact(meta_client_name)) AS nodes,
        formatDateTime(min(slot_start_date_time), '%Y-%m-%d') AS first_seen,
        formatDateTime(max(slot_start_date_time), '%Y-%m-%d') AS last_seen
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_head
    WHERE slot_start_date_time BETWEEN '2026-06-25 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY impl
) h
GLOBAL LEFT JOIN (
    SELECT
        meta_consensus_implementation AS impl,
        arrayStringConcat(groupUniqArray(meta_consensus_version), ', ') AS versions
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_head
    WHERE slot_start_date_time BETWEEN '2026-07-08 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY impl
) v ON h.impl = v.impl
ORDER BY impl
