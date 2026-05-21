# Default upstream Pulsarr image. CI does not need to override this; bump the
# version here in lockstep with `pulsarr/build.yaml` and `pulsarr/config.yaml`
# whenever you pin a new Pulsarr release.
ARG BUILD_FROM=lakker/pulsarr:0.15.5
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Switch to root for installing utilities. The upstream entrypoint will
# drop privileges to PUID/PGID via su-exec at runtime.
USER root

# bashio is a bash-based helper used by Home Assistant add-ons to read
# /data/options.json. The upstream lakker/pulsarr image is alpine-based
# and ships only busybox sh, so we install bash + jq + curl here.
# hadolint ignore=DL3018
RUN apk add --no-cache bash jq curl

# Pull bashio runtime from the canonical HA add-on base image. We do not
# inherit FROM that image because lakker/pulsarr is our base; we only need
# the bashio helper scripts.
#
# Note: in the upstream image /usr/bin/bashio is a symlink to
# /usr/lib/bashio/bashio. Copying the symlink target via COPY --from would
# produce a regular file in /usr/bin and break bashio (it locates its modules
# via `dirname "$BASH_SOURCE"`). We re-create the symlink instead.
COPY --from=ghcr.io/hassio-addons/base:20.1.1 /usr/lib/bashio /usr/lib/bashio
COPY --from=ghcr.io/hassio-addons/base:20.1.1 /usr/bin/tempio /usr/bin/tempio
RUN ln -sf /usr/lib/bashio/bashio /usr/bin/bashio

COPY rootfs/run.sh /run.sh
RUN chmod a+x /run.sh

# Disable the upstream Docker HEALTHCHECK. The upstream check probes
# `${basePath}/health` using `${basePath}` from environment, but env vars set
# by /run.sh (where we compute the dynamic Ingress path) are not visible to
# the HEALTHCHECK CMD process. With basePath empty inside HEALTHCHECK, every
# probe hits bare `/health`, which Pulsarr serves only under basePath when
# running behind HA Ingress, producing 404 spam in logs. HA Supervisor has
# its own watchdog mechanism for add-ons, so the Docker-level check is
# redundant here.
HEALTHCHECK NONE

# ENTRYPOINT ["/sbin/tini", "--"] is inherited from lakker/pulsarr and
# handles signals + zombie reaping. We only override CMD to bootstrap
# Home Assistant options before starting Pulsarr.
CMD ["/run.sh"]
