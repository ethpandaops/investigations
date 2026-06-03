SELECT DISTINCT validator_index AS validator_index
FROM default.mev_relay_validator_registration
WHERE meta_network_name = 'mainnet'
  AND slot_start_date_time >= '2025-06-01' AND slot_start_date_time < '2026-06-01'
