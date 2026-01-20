-- Attester-based head vote accuracy summary by entity type
-- Shows: What % of entity X's attestations vote for the correct head?
-- Uses 1 week due to table size
-- Uses UNION approach to include "Other" without expensive full join
WITH validator_entities AS (
    SELECT
        validator_index,
        argMax(source, updated_date_time) as entity
    FROM mainnet.dim_node
    WHERE source IN ('solo_stakers', 'rocketpool')
        OR source LIKE 'csm_operator%'
    GROUP BY validator_index
),
-- Stats for known entity groups
known_groups AS (
    SELECT
        CASE
            WHEN ve.entity LIKE 'csm_operator%' THEN 'Lido CSM'
            WHEN ve.entity = 'rocketpool' THEN 'Rocketpool'
            WHEN ve.entity = 'solo_stakers' THEN 'Solo Stakers'
        END as entity_group,
        countIf(h.slot_distance = 0) as correct_head,
        count(*) as total
    FROM mainnet.fct_attestation_correctness_by_validator_head h
    INNER JOIN validator_entities ve ON h.attesting_validator_index = ve.validator_index
    WHERE h.slot_start_date_time >= now() - INTERVAL 1 WEEK
    AND h.slot_distance IS NOT NULL
    GROUP BY entity_group
),
-- Network-wide totals
network_totals AS (
    SELECT
        countIf(slot_distance = 0) as correct_head,
        count(*) as total
    FROM mainnet.fct_attestation_correctness_by_validator_head
    WHERE slot_start_date_time >= now() - INTERVAL 1 WEEK
    AND slot_distance IS NOT NULL
),
-- Sum of known groups
known_sums AS (
    SELECT
        sum(correct_head) as correct_head,
        sum(total) as total
    FROM known_groups
)
SELECT entity_group, toInt64(correct_head) as correct_head, toInt64(total) as total, round(correct_head * 100.0 / total, 2) as head_accuracy_pct
FROM known_groups
UNION ALL
SELECT
    'Other' as entity_group,
    toInt64(nt.correct_head - ks.correct_head) as correct_head,
    toInt64(nt.total - ks.total) as total,
    round((nt.correct_head - ks.correct_head) * 100.0 / (nt.total - ks.total), 2) as head_accuracy_pct
FROM network_totals nt, known_sums ks
ORDER BY total DESC
