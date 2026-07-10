-- Classifies Prysm peers by how often they were caught behind on block processing
-- Results pinned from the original 2026-02-05 12:00-12:15 run: the raw libp2p
-- tables for that window have since aged out of ClickHouse retention, so the
-- query can no longer be re-executed. Original query in git history.
SELECT category, peer_count, avg_behind_pct, total_peak_msgs, total_tail_msgs, total_msgs
FROM values(
    'category String, peer_count UInt64, avg_behind_pct Float64, total_peak_msgs UInt64, total_tail_msgs UInt64, total_msgs UInt64',
    ('Rarely (<10%)', 1948, 0.1, 439687, 465951, 905638),
    ('Sometimes (10-40%)', 18, 20.1, 1521, 154, 1675),
    ('Often (40-80%)', 5, 62.7, 3483, 374, 3857),
    ('Always (>80%)', 115, 99.9, 63, 54, 117)
)
