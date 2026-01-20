-- Attester-based head vote accuracy by entity type and blob count
-- Shows: How does entity X's head accuracy change with blob count?
-- Uses 1 week due to table size
-- Note: "Other" excluded from this query due to performance constraints
WITH validator_entities AS (
    SELECT
        validator_index,
        argMax(source, updated_date_time) as entity
    FROM mainnet.dim_node
    WHERE source IN ('solo_stakers', 'rocketpool')
        OR source LIKE 'csm_operator%'
    GROUP BY validator_index
)
SELECT
    CASE
        WHEN ve.entity LIKE 'csm_operator%' THEN 'Lido CSM'
        WHEN ve.entity = 'rocketpool' THEN 'Rocketpool'
        WHEN ve.entity = 'solo_stakers' THEN 'Solo Stakers'
    END as entity_group,
    COALESCE(b.blob_count, 0) as blob_count,
    countIf(h.slot_distance = 0) as correct_head,
    count(*) as total,
    round(countIf(h.slot_distance = 0) * 100.0 / count(*), 2) as head_accuracy_pct
FROM mainnet.fct_attestation_correctness_by_validator_head h
INNER JOIN validator_entities ve ON h.attesting_validator_index = ve.validator_index
LEFT JOIN mainnet.fct_block_blob_count_head b FINAL ON h.slot = b.slot
WHERE h.slot_start_date_time >= now() - INTERVAL 1 WEEK
AND h.slot_distance IS NOT NULL
GROUP BY entity_group, blob_count
ORDER BY entity_group, blob_count
