# Changelog

## 0.15.5-2

- Fix: chown `/data` to PUID/PGID (defaults 1000:1000) before handing off to
  the upstream entrypoint. Without this, Bun running under su-exec could not
  create `/data/db/pulsarr.db` and migrations failed with `SQLITE_CANTOPEN`
  (errno 14). The upstream entrypoint only chowns `/app/data`, but we relocate
  the DB to `/data` (the HA-managed persistent volume), so the wrapper has to
  align the ownership itself.

## 0.15.5-1

- Fix: re-create `/usr/bin/bashio` as a symlink to `/usr/lib/bashio/bashio`
  instead of copying it as a regular file. Without the symlink, bashio's
  module resolution (`dirname "$BASH_SOURCE"`) pointed at `/usr/bin/`, where
  the helper scripts (`bashio.sh`, `config.sh`, ...) do not live, breaking
  add-on startup with `/usr/bin/bashio.sh: No such file or directory`.

## 0.15.5

Initial public release of the Home Assistant add-on packaging.

- Wraps upstream `lakker/pulsarr:0.15.5`.
- Multi-arch build for `amd64` and `aarch64` published to GHCR.
- Home Assistant Ingress with auto-detected `basePath`.
- Add-on options: `log_level`, `auth_method`, `tz`, `database` (SQLite or
  external PostgreSQL), `apprise_url`.
- SQLite stored under `/data/db/pulsarr.db` (included in HA snapshots).
- `share` and `media` HA folders mounted read-write inside the container.
