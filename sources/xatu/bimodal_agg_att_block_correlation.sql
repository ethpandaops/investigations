-- Per-slot correlation between aggregate tail P50 and next-slot block arrival
-- For each slot N: tail P50 of aggregates vs block P50 arrival at slot N+1
-- Fixed time window: 2026-02-05 to 2026-02-06
SELECT
    agg.slot AS slot,
    agg.tail_p50 AS tail_p50,
    blk.next_block_p50 AS next_block_p50
FROM (
    SELECT
        slot,
        round(quantile(0.5)(propagation_slot_start_diff)) AS tail_p50
    FROM default.libp2p_gossipsub_aggregate_and_proof
    WHERE meta_network_name = 'mainnet'
    AND slot_start_date_time >= '2026-02-05T00:00:00'
    AND slot_start_date_time < '2026-02-06T00:00:00'
    AND propagation_slot_start_diff BETWEEN 12000 AND 20000
    GROUP BY slot
) agg
INNER JOIN (
    SELECT
        slot - 1 AS agg_slot,
        round(quantile(0.5)(propagation_slot_start_diff)) AS next_block_p50
    FROM default.libp2p_gossipsub_beacon_block
    WHERE meta_network_name = 'mainnet'
    AND slot_start_date_time >= '2026-02-05T00:00:00'
    AND slot_start_date_time < '2026-02-06T00:00:00'
    AND propagation_slot_start_diff BETWEEN 0 AND 12000
    GROUP BY slot
) blk ON agg.slot = blk.agg_slot
ORDER BY agg.slot ASC
