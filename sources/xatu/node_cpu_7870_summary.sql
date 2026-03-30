-- EIP-7870 reference node CPU from Prometheus container_cpu_usage_seconds_total
-- All nodes run Prysm CL with different EL clients, 24h average on 2026-03-30
-- Source: rate(container_cpu_usage_seconds_total[2m]) over 24h at 1m resolution
SELECT *
FROM (
    SELECT 'geth' as el_client, 0.89 as cl_avg_cores, 1.03 as cl_p95_cores, 0.25 as el_avg_cores, 0.33 as el_p95_cores, 1.14 as total_avg_cores
    UNION ALL
    SELECT 'besu', 0.60, 0.68, 0.31, 0.39, 0.91
    UNION ALL
    SELECT 'nethermind', 0.58, 0.67, 0.19, 0.27, 0.77
    UNION ALL
    SELECT 'reth', 0.56, 0.64, 0.48, 0.74, 1.04
    UNION ALL
    SELECT 'ethrex', 0.58, 0.66, 0.27, 0.31, 0.85
    UNION ALL
    SELECT 'erigon', 0.49, 0.63, 0.15, 0.25, 0.64
)
ORDER BY total_avg_cores DESC
