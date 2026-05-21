# Changelog

## 0.15.5-4

- Fix: replace `HEALTHCHECK NONE` with a TCP-only probe via bash's built-in
  `/dev/tcp` redirector. Without a healthcheck, HA Supervisor cannot mark the
  add-on as `started`, leaving the HA frontend in a perpetual loading spinner
  when opening the Web UI. The TCP probe verifies that Pulsarr is listening
  on port 3003 without issuing HTTP requests that depend on the Ingress
  basePath, avoiding the 404 log spam that broke 0.15.5-3 and earlier.

## 0.15.5-3

- Fix: disable the inherited Docker `HEALTHCHECK` (`HEALTHCHECK NONE`). The
  upstream check shells out to `${basePath}/health`, but environment variables
  exported by `/run.sh` are not visible to Docker's HEALTHCHECK process, so
  `${basePath}` was always empty inside the probe. That caused the probe to
  hit bare `/health`, which Pulsarr serves only under the Ingress basePath,
  producing repeated 404 entries in the add-on log. HA Supervisor has its own
  watchdog mechanism for add-ons, making the Docker-level check redundant
  here.

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
