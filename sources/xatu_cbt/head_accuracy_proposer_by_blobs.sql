-- Proposer-based head vote accuracy by entity type and blob count
-- Shows: How does head vote % change with blob count when entity X proposes?
WITH proposer_entities AS (
    SELECT
        slot,
        CASE
            WHEN entity LIKE 'csm_operator%' THEN 'Lido CSM'
            WHEN entity = 'rocketpool' THEN 'Rocketpool'
            WHEN entity = 'solo_stakers' THEN 'Solo Stakers'
            ELSE 'Other'
        END as entity_group
    FROM mainnet.fct_block_proposer_entity FINAL
    WHERE slot_start_date_time >= now() - INTERVAL 4 WEEK
)
SELECT
    pe.entity_group,
    COALESCE(b.blob_count, 0) as blob_count,
    sum(h.votes_head) as votes_for_head,
    sum(h.votes_max) as total_votes,
    round(100.0 * sum(h.votes_head) / sum(h.votes_max), 2) as head_vote_pct
FROM mainnet.fct_attestation_correctness_head h FINAL
INNER JOIN proposer_entities pe ON h.slot = pe.slot
LEFT JOIN mainnet.fct_block_blob_count_head b FINAL ON h.slot = b.slot
WHERE h.slot_start_date_time >= now() - INTERVAL 4 WEEK
AND h.votes_head IS NOT NULL
GROUP BY pe.entity_group, blob_count
ORDER BY pe.entity_group, blob_count
