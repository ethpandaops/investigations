SELECT
    client_type,
    wallclock_slot % 32 as slot_in_epoch,
    round(avg(least(total_on_cpu_ns / (interval_ms * 1000000), system_cores)), 3) as avg_cores
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
GROUP BY client_type, slot_in_epoch
ORDER BY client_type, slot_in_epoch ASC
