-- Per-client event counts for the six new Glamsterdam beacon API SSE event tables
-- on glamsterdam-devnet-6. Attribution via meta_consensus_implementation of the
-- beacon node each xatu-sentry is attached to.
-- Fixed window: 2026-06-25 (devnet-6 genesis) to 2026-07-09 23:59:59 UTC.
SELECT event, impl, cnt FROM (
    SELECT 'execution_payload' AS event, meta_consensus_implementation AS impl, toFloat64(count()) AS cnt
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_execution_payload
    WHERE slot_start_date_time BETWEEN '2026-06-25 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY impl
    UNION ALL
    SELECT 'execution_payload_available', meta_consensus_implementation, toFloat64(count())
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_execution_payload_available
    WHERE slot_start_date_time BETWEEN '2026-06-25 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY 2
    UNION ALL
    SELECT 'execution_payload_bid', meta_consensus_implementation, toFloat64(count())
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_execution_payload_bid
    WHERE slot_start_date_time BETWEEN '2026-06-25 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY 2
    UNION ALL
    SELECT 'execution_payload_gossip', meta_consensus_implementation, toFloat64(count())
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_execution_payload_gossip
    WHERE slot_start_date_time BETWEEN '2026-06-25 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY 2
    UNION ALL
    SELECT 'payload_attestation', meta_consensus_implementation, toFloat64(count())
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_payload_attestation
    WHERE slot_start_date_time BETWEEN '2026-06-25 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY 2
    UNION ALL
    SELECT 'proposer_preferences', meta_consensus_implementation, toFloat64(count())
    FROM `glamsterdam-devnet-6`.beacon_api_eth_v1_events_proposer_preferences
    WHERE slot_start_date_time BETWEEN '2026-06-25 00:00:00' AND '2026-07-09 23:59:59'
    GROUP BY 2
)
ORDER BY event, impl
