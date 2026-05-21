# Changelog

## 0.15.5

Initial public release of the Home Assistant add-on packaging.

- Wraps upstream `lakker/pulsarr:0.15.5`.
- Multi-arch build for `amd64` and `aarch64` published to GHCR.
- Home Assistant Ingress with auto-detected `basePath`.
- Add-on options: `log_level`, `auth_method`, `tz`, `database` (SQLite or
  external PostgreSQL), `apprise_url`.
- SQLite stored under `/data/db/pulsarr.db` (included in HA snapshots).
- `share` and `media` HA folders mounted read-write inside the container.
