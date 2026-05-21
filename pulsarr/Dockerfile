ARG BUILD_FROM
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
COPY --from=ghcr.io/hassio-addons/base:20.1.1 /usr/lib/bashio /usr/lib/bashio
COPY --from=ghcr.io/hassio-addons/base:20.1.1 /usr/bin/bashio /usr/bin/bashio
COPY --from=ghcr.io/hassio-addons/base:20.1.1 /usr/bin/tempio /usr/bin/tempio

COPY rootfs/run.sh /run.sh
RUN chmod a+x /run.sh

# ENTRYPOINT ["/sbin/tini", "--"] is inherited from lakker/pulsarr and
# handles signals + zombie reaping. We only override CMD to bootstrap
# Home Assistant options before starting Pulsarr.
CMD ["/run.sh"]
