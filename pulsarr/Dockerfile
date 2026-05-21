# Default upstream Pulsarr image. CI does not need to override this; bump the
# version here in lockstep with `pulsarr/build.yaml` and `pulsarr/config.yaml`
# whenever you pin a new Pulsarr release.
ARG BUILD_FROM=lakker/pulsarr:0.15.5
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Switch to root for installing utilities. The upstream entrypoint will
# drop privileges to PUID/PGID via su-exec at runtime.
USER root

# - bash + jq + curl: needed by bashio (the upstream image is alpine-based and
#   ships only busybox sh).
# - nginx: in-container reverse proxy that strips the rotating
#   `/api/hassio_ingress/<TOKEN>` prefix Home Assistant prepends before each
#   request. See rootfs/etc/nginx/nginx.conf for the full rationale.
# - iproute2: provides `ss`, used by run.sh to log who owns :3003 / :8989.
# hadolint ignore=DL3018
RUN apk add --no-cache bash jq curl nginx iproute2

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

# Drop our own nginx.conf in place of the alpine default. /etc/nginx/http.d/*
# is intentionally not used because we prefer one self-contained file rather
# than splitting between /etc/nginx/nginx.conf and a separate site config.
COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# Make sure nginx's runtime directories are writable by root (we run nginx as
# root inside the container; Pulsarr itself is dropped to PUID/PGID by the
# upstream entrypoint).
RUN mkdir -p /var/log/nginx /var/lib/nginx /run/nginx \
    && rm -f /etc/nginx/http.d/default.conf

COPY rootfs/run.sh /run.sh
RUN chmod a+x /run.sh

# A TCP-level probe satisfies the Supervisor (the port is open once nginx is
# listening) without issuing HTTP requests against routes that depend on the
# Ingress prefix. bash ships in this image, and /dev/tcp/<host>/<port> is
# bash's built-in TCP redirector, so no extra dependencies are required.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --start-interval=10s --retries=3 \
    CMD bash -c '> /dev/tcp/127.0.0.1/3003' || exit 1

# ENTRYPOINT ["/sbin/tini", "--"] is inherited from lakker/pulsarr and
# handles signals + zombie reaping. We only override CMD to bootstrap
# Home Assistant options before starting Pulsarr.
CMD ["/run.sh"]
