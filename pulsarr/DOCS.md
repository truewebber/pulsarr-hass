# Home Assistant Add-on: Pulsarr

Pulsarr bridges Plex watchlists with Sonarr and Radarr for real-time media
monitoring and automated content acquisition. This add-on packages the official
[`lakker/pulsarr`](https://hub.docker.com/r/lakker/pulsarr) image so that you
can install Pulsarr from inside Home Assistant OS or HA Supervised with one
click and access its UI through HA Ingress.

## Installation

1. In Home Assistant go to **Settings → Add-ons → Add-on Store**.
2. Open the **⋮** menu in the top-right corner and choose **Repositories**.
3. Add the URL of this repository:
   `https://github.com/truewebber/pulsarr-hass`.
4. Refresh the store, find **Pulsarr** under "truewebber Add-ons" and click
   **Install**.
5. After installation, click **Start**, then **Open Web UI** to reach the
   Pulsarr setup wizard through Home Assistant Ingress.

## Configuration

All add-on options are surfaced in the **Configuration** tab. The options below
only cover infrastructure concerns (timezone, logging, auth, database).
Everything else — Plex token, Sonarr/Radarr connections, content routing rules,
quotas, Discord, Apprise routes — is configured inside the Pulsarr web UI
because it provides interactive forms, OAuth flows and "Test connection"
helpers that environment variables cannot replicate.

### `log_level`

Controls verbosity of Pulsarr's structured logs. Output is sent to the
add-on's stdout, which Home Assistant captures into the **Log** tab.

| Value     | Use when                                             |
| --------- | ---------------------------------------------------- |
| `trace`   | Diagnosing very low-level routing decisions           |
| `debug`   | Debugging webhook delivery or watchlist polling       |
| `info`    | Default. Normal production verbosity                  |
| `warn`    | Production with quiet logs                           |
| `error`   | Only failures                                         |
| `fatal`   | Process-killing errors only                          |
| `silent`  | Disable logging entirely (not recommended)            |

### `auth_method`

How Pulsarr should authenticate users hitting its UI / API.

| Value                  | Behaviour                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `requiredExceptLocal`  | Default. HA Ingress connections are treated as local and skip Pulsarr login; direct port access still requires Pulsarr auth. |
| `required`             | Always require Pulsarr login, even via Ingress. Causes a double login when used with HA Ingress.                              |
| `disabled`             | No authentication. Only safe when the add-on is reachable exclusively through HA Ingress (no port published).                 |

### `tz`

Optional. IANA timezone name (e.g. `Europe/Berlin`, `America/Los_Angeles`).
When unset, the add-on uses the host timezone reported by Supervisor.

### `database.type`

`sqlite` (default) or `postgres`.

- **SQLite**: zero configuration. The database file lives at
  `/data/db/pulsarr.db` inside the add-on's persistent volume and is included
  in HA snapshots.
- **PostgreSQL**: requires `database.host`, `database.name`, `database.user`,
  `database.password`. Optional `database.port` (default `5432`). The database
  must already exist and be reachable from inside the HA Docker network.

### `apprise_url`

Optional URL of an Apprise API server (e.g. another HA add-on or a separate
container). When set, Pulsarr can dispatch notifications via Apprise's 80+
notification backends.

## Networking, ports and Ingress

By default this add-on is reachable **only through HA Ingress**: there is no
host port mapping, no exposure to your LAN, and HA's authentication protects
access. If you need direct LAN access (for example to point the Pulsarr
mobile bookmark or a third-party integration at port 3003), edit the **Network**
section in the **Configuration** tab and assign a host port to `3003/tcp`.

When direct port access is enabled, set `auth_method` to `required` or
`requiredExceptLocal` so that Pulsarr's own login still protects the port.

## Storage layout

| Path inside container | Purpose                                  | Persistent? |
| --------------------- | ---------------------------------------- | ----------- |
| `/data/db`            | SQLite database file                     | Yes (HA volume + snapshots) |
| `/data/logs`          | Application log files                    | Yes (HA volume + snapshots) |
| `/app/data`           | Inherited VOLUME from upstream (unused)  | No (anon)   |

Pulsarr does **not** need access to the media library on disk — managing files
is Sonarr's and Radarr's job. Pulsarr only talks to those services over HTTP.
For that reason this add-on does not map `/share` or `/media` into the
container; everything Pulsarr persists lives under `/data`, which is the
add-on's own HA-managed volume and is included in HA snapshots.

## First-run checklist

1. Open the add-on, complete the Pulsarr setup wizard.
2. Authenticate against Plex through the Pulsarr UI to obtain a Plex token.
3. Add at least one Sonarr instance and one Radarr instance with their API
   keys. Make sure the URL is reachable from inside the HA Docker network —
   for community add-ons by `alexbelgium`, this is typically
   `http://<addon-slug>:8989` for Sonarr and `http://<addon-slug>:7878` for
   Radarr.
4. Pick root folders and quality profiles in Pulsarr's settings.
5. (Plex Pass users) Configure the Plex webhook URL Pulsarr displays so the
   sync becomes real-time. Without Plex Pass, Pulsarr falls back to a
   5-minute polling loop.

## Upgrading

This add-on pins a specific Pulsarr release in `config.yaml` (currently
`0.15.5`). New Pulsarr versions are released as new add-on versions; HA shows
the available update banner and a one-click upgrade button. Snapshots are
recommended before any upgrade.

## Troubleshooting

- **The add-on starts but the Web UI button does nothing.** Check the **Log**
  tab. Most common cause is `basePath` mismatch; the add-on auto-detects it
  from `bashio::addon.ingress_entry` so this should never happen — please
  open an issue with the log if it does.
- **Cannot reach Sonarr/Radarr from Pulsarr.** Use the add-on's docker-network
  hostname (e.g. `a0d7b954-sonarr`) rather than `localhost`. Hostnames are
  shown on each add-on's **Info** tab.
- **PostgreSQL connection refused.** Verify that the Postgres host is in the
  HA Docker network and listening on the configured port. The HA Postgres
  add-on does not expose a Docker network alias by default; consider running
  Postgres as a separate add-on with explicit `host_network` or via Portainer.
- **Cookies not persisting / login loops via Ingress.** Should not happen
  with default settings (`cookieSecured=false`). If you have customised
  Pulsarr to require secure cookies, you will get login loops behind Ingress.

## Upstream

- Pulsarr project: <https://github.com/jamcalli/Pulsarr>
- Pulsarr docs: <https://jamcalli.github.io/Pulsarr/>
- Add-on source: <https://github.com/truewebber/pulsarr-hass>

## License

Add-on packaging files in this repository are MIT-licensed. The Pulsarr
application itself is AGPL-3.0; see `/LICENSE` in the add-on container.
