SELECT
    client_type,
    CASE
        WHEN wallclock_slot % 32 = 0 THEN 'epoch_start'
        WHEN wallclock_slot % 32 = 31 THEN 'epoch_end'
        ELSE 'mid_epoch'
    END as epoch_position,
    toUInt32(
        (toUnixTimestamp64Milli(window_start) - toUnixTimestamp64Milli(wallclock_slot_start_date_time)) / 200
    ) as window_in_slot,
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
GROUP BY client_type, epoch_position, window_in_slot
HAVING window_in_slot >= 0 AND window_in_slot <= 59
ORDER BY client_type, epoch_position, window_in_slot ASC
