# Pulsarr Home Assistant Add-on

Home Assistant OS / Supervised add-on that packages
[Pulsarr](https://github.com/jamcalli/Pulsarr) — a real-time Plex watchlist
monitor that bridges Plex with Sonarr and Radarr.

This repository contains add-on metadata and a thin Docker wrapper around the
official `lakker/pulsarr` image. The add-on exposes Pulsarr through Home
Assistant Ingress (no extra port to publish, no second login), with all
infrastructure settings surfaced in the HA Configuration UI.

## Install

1. In Home Assistant: **Settings → Add-ons → Add-on Store**.
2. Open the **⋮** menu → **Repositories**.
3. Add `https://github.com/truewebber/pulsarr-hass` and click **Add**.
4. Refresh the store, find **Pulsarr** under **truewebber Add-ons**.
5. Click **Install** → **Start** → **Open Web UI** to reach the Pulsarr setup
   wizard via HA Ingress.

Detailed configuration documentation is in [`pulsarr/DOCS.md`](pulsarr/DOCS.md).

## Supported architectures

| Architecture | Tag                                                 |
| ------------ | --------------------------------------------------- |
| `amd64`      | `ghcr.io/truewebber/amd64-pulsarr-hass:<version>`   |
| `aarch64`    | `ghcr.io/truewebber/aarch64-pulsarr-hass:<version>` |

`armv7`, `armhf` and `i386` are intentionally not supported because upstream
`lakker/pulsarr` only publishes `amd64` and `arm64` images.

## How this works

- **Base image**: `lakker/pulsarr:0.15.5` (multi-arch upstream).
- **Wrapper**: `bash` + `bashio` are layered on top to read HA add-on options
  from `/data/options.json` and translate them into Pulsarr's environment
  variables (`TZ`, `logLevel`, `authenticationMethod`, `dbType`, `dbPath`,
  `basePath`, ...).
- **Init**: upstream `tini` PID 1 + Pulsarr's `docker-entrypoint.sh` (handles
  `PUID`/`PGID` and runs migrations). The add-on's `run.sh` only configures
  environment, then `exec`s the upstream entrypoint.
- **Ingress**: `bashio::addon.ingress_entry` is exported as Pulsarr's
  `basePath`, so the UI works behind HA's reverse proxy without any other
  configuration.
- **Persistence**: SQLite lives in `/data/db/pulsarr.db` (HA add-on volume,
  included in snapshots). External PostgreSQL is also supported via add-on
  options.

## Build and release

CI (`.github/workflows/builder.yaml`) uses
[`home-assistant/builder`](https://github.com/home-assistant/builder) to
produce `linux/amd64` and `linux/arm64` images and push them to GHCR. To cut a
release:

1. Bump `version` in `pulsarr/config.yaml` to match the upstream Pulsarr
   release you want to pin (e.g. `0.15.6`).
2. Update `pulsarr/build.yaml` `build_from` tags to the same upstream version.
3. Add a `pulsarr/CHANGELOG.md` entry.
4. Commit, push, then create a GitHub release with tag `v<version>`.

The `release` event triggers a clean multi-arch build that publishes
`ghcr.io/truewebber/{arch}-pulsarr-hass:<version>` and updates the `latest`
tag.

## License

The add-on packaging files (Dockerfile, `run.sh`, `config.yaml`, CI, docs) in
this repository are licensed under the [MIT License](LICENSE).

The upstream Pulsarr application is licensed under the
[GNU Affero General Public License v3.0](https://github.com/jamcalli/Pulsarr/blob/master/LICENSE)
and is **not** relicensed by this repository. The MIT license applies only to
the packaging code authored here. Any binary distribution of the add-on
container therefore inherits AGPL-3.0 obligations for the Pulsarr code inside
it; users who modify Pulsarr itself must comply with AGPL-3.0.

## Disclaimers

- This is a **community add-on**. It is not affiliated with the Pulsarr
  upstream project, with Plex, Inc., or with the Home Assistant developers.
- "Pulsarr", "Plex", "Sonarr" and "Radarr" are trademarks of their respective
  owners.
- Use at your own risk. Always take an HA snapshot before installing or
  upgrading the add-on.
