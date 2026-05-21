#!/usr/bin/env bashio
# ==============================================================================
# Home Assistant add-on: Pulsarr
#
# This script translates Home Assistant add-on options (read by bashio from
# /data/options.json) into the environment variables that the upstream Pulsarr
# server expects, then hands control to Pulsarr's own docker-entrypoint.sh.
#
# Reference: https://pulsarr.dev/docs/development/environment-variables
# ==============================================================================
set -eo pipefail

# ------------------------------------------------------------------------------
# Timezone
# ------------------------------------------------------------------------------
# If the user did not override `tz` in add-on options, fall back to the host
# timezone reported by Supervisor.
if bashio::config.has_value 'tz'; then
    TZ_VALUE="$(bashio::config 'tz')"
else
    TZ_VALUE="$(bashio::supervisor.timezone)"
fi
export TZ="${TZ_VALUE}"

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------
LOG_LEVEL_VALUE="$(bashio::config 'log_level')"
export logLevel="${LOG_LEVEL_VALUE}"

# ------------------------------------------------------------------------------
# Authentication
# ------------------------------------------------------------------------------
# `requiredExceptLocal` (default) avoids a double login when the UI is opened
# through HA Ingress, while still requiring auth for direct port access.
AUTH_METHOD_VALUE="$(bashio::config 'auth_method')"
export authenticationMethod="${AUTH_METHOD_VALUE}"

# ------------------------------------------------------------------------------
# Database
# ------------------------------------------------------------------------------
DB_TYPE_VALUE="$(bashio::config 'database.type')"
if [ "${DB_TYPE_VALUE}" = "postgres" ]; then
    if ! bashio::config.has_value 'database.host' \
        || ! bashio::config.has_value 'database.name' \
        || ! bashio::config.has_value 'database.user' \
        || ! bashio::config.has_value 'database.password'; then
        bashio::exit.nok \
            "database.type is 'postgres' but host/name/user/password are not all set"
    fi

    export dbType="postgres"
    export dbHost="$(bashio::config 'database.host')"
    export dbPort="$(bashio::config 'database.port' '5432')"
    export dbName="$(bashio::config 'database.name')"
    export dbUser="$(bashio::config 'database.user')"
    export dbPassword="$(bashio::config 'database.password')"
else
    # SQLite is the default. Persist the database under /data so it survives
    # add-on restarts, version upgrades and HA snapshots.
    export dbPath="/data/db/pulsarr.db"
fi

# ------------------------------------------------------------------------------
# Apprise notifications (optional)
# ------------------------------------------------------------------------------
if bashio::config.has_value 'apprise_url'; then
    export appriseUrl="$(bashio::config 'apprise_url')"
fi

# ------------------------------------------------------------------------------
# Reverse-proxy / Ingress wiring
# ------------------------------------------------------------------------------
# bashio::addon.ingress_entry returns the absolute path that HA reverse-proxies
# to this add-on, e.g. "/api/hassio_ingress/<token>". Pulsarr serves its UI and
# REST API under this prefix when `basePath` is set.
INGRESS_PATH="$(bashio::addon.ingress_entry)"
export basePath="${INGRESS_PATH}"

# Internal port; the add-on's `ingress_port` in config.yaml must match this.
export listenPort="3003"

# HA Ingress terminates TLS upstream and talks plain HTTP into the add-on.
# Telling Pulsarr that cookies are not served over HTTPS keeps session cookies
# functional inside the Ingress proxy.
export cookieSecured="false"

# ------------------------------------------------------------------------------
# Persistent storage
# ------------------------------------------------------------------------------
# /data is the per-add-on persistent volume managed by Supervisor. Supervisor
# mounts the path as root:root, but the upstream docker-entrypoint will
# su-exec into PUID/PGID (defaulting to 1000:1000) before launching Pulsarr.
# We have to align ownership of /data with that uid/gid here, otherwise the
# Bun process cannot create /data/db/pulsarr.db (SQLITE_CANTOPEN, errno 14).
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
export PUID PGID

mkdir -p /data/db /data/logs
chown -R "${PUID}:${PGID}" /data

# ------------------------------------------------------------------------------
# Hand off to upstream entrypoint
# ------------------------------------------------------------------------------
bashio::log.info "Starting Pulsarr"
bashio::log.info "  TZ=${TZ}"
bashio::log.info "  logLevel=${logLevel}"
bashio::log.info "  authenticationMethod=${authenticationMethod}"
bashio::log.info "  dbType=${DB_TYPE_VALUE}"
bashio::log.info "  basePath=${basePath}"
bashio::log.info "  listenPort=${listenPort}"

cd /app
exec ./docker-entrypoint.sh
