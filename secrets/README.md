# secrets/

This whole directory is gitignored. Files here are mounted read-only into
containers that need a credential as a file rather than an env var. Populate
them yourself; nothing in here should ever be committed.

- `pihole/api-key` -- Pi-hole API key, used by the Dashy pi-hole-stats-v6 widget.
- `prometheus/k3s-ca.crt` -- CA cert for the k3s API server (kubernetes-state scrape job).
- `prometheus/k3s-scraper.token` -- bearer token for the k3s kube-state-metrics scrape.
- `prometheus/pve.yml` -- pve-exporter config (Proxmox API user/token for the `pve` scrape job):
  ```yaml
  default:
      user: prometheus@pve
      token_name: prometheus
      token_value: "..."
      verify_ssl: false
  ```
- `uptime-kuma/api-key` -- Uptime Kuma API key, used by the Dashy uptime-kuma widget.
