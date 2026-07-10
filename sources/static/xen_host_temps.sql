-- Hardware temperatures for the six utility 7870 hosts (one dedicated host per EL client)
-- CPU = k10temp Tctl, NVMe = hottest sensor across both drives. 15-minute samples from
-- node_exporter via the platform Prometheus, fixed window 2026-07-08 00:00 to 2026-07-10 00:00 UTC.
SELECT
    ts_label,
    ts,
    host,
    client,
    cpu_c,
    nvme_c
FROM read_csv_auto('sources/static/xen_host_temps.csv', header = true)
ORDER BY ts, host
