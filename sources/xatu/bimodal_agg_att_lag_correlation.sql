-- Per-slot peer behavior: does catching a Prysm peer behind on block processing
-- predict what they forward to us?
-- Results pinned from the original 2026-02-05 12:00-12:15 run: the raw libp2p
-- tables for that window have since aged out of ClickHouse retention, so the
-- query can no longer be re-executed. Original query in git history.
SELECT state, behavior, cnt, pct
FROM values(
    'state String, behavior String, cnt UInt64, pct Float64',
    ('Had block', 'Sent nothing', 27405, 58.4),
    ('Had block', 'Only peak', 10491, 22.4),
    ('Had block', 'Peak and tail', 6331, 13.5),
    ('Had block', 'Only tail', 2661, 5.7),
    ('Caught behind', 'Sent nothing', 2347, 96.5),
    ('Caught behind', 'Only peak', 59, 2.4),
    ('Caught behind', 'Peak and tail', 7, 0.3),
    ('Caught behind', 'Only tail', 18, 0.7)
)
