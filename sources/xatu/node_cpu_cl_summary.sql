SELECT
    client_type,
    round(avg(least(total_on_cpu_ns / (interval_ms * 1000000), system_cores)), 2) as avg_cores,
    round(quantile(0.50)(least(total_on_cpu_ns / (interval_ms * 1000000), system_cores)), 2) as p50_cores,
    round(quantile(0.95)(least(total_on_cpu_ns / (interval_ms * 1000000), system_cores)), 2) as p95_cores,
    round(quantile(0.99)(least(total_on_cpu_ns / (interval_ms * 1000000), system_cores)), 2) as p99_cores,
    round(max(least(total_on_cpu_ns / (interval_ms * 1000000), system_cores)), 2) as peak_cores
FROM observoor.cpu_utilization
WHERE meta_network_name = 'mainnet'
  AND client_type IN ('lighthouse', 'prysm', 'lodestar', 'nimbus')
  AND meta_client_name IN (
    'utility-mainnet-lighthouse-geth-001',
    'utility-mainnet-prysm-geth-tysm-001',
    'utility-mainnet-lodestar-nethermind-001',
    'utility-mainnet-nimbus-besu-001'
  )
  AND window_start >= '2026-03-10'
  AND window_start < '2026-03-17'
GROUP BY client_type
ORDER BY avg_cores ASC
