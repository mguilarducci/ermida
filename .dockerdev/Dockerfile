# syntax=docker/dockerfile:1

# Development image only. Production uses the Dockerfile at the repo root (Kamal).
# Gems are not baked in: they live in the `bundle` volume (see compose.yml).
ARG RUBY_VERSION
ARG DISTRO_NAME=trixie

FROM ruby:$RUBY_VERSION-slim-$DISTRO_NAME

# ARGs declared before FROM are reset after it
ARG DISTRO_NAME
ARG PG_MAJOR
ARG USER_UID=1000
ARG USER_GID=1000

# Keep downloaded packages in the BuildKit cache instead of deleting them
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# PostgreSQL apt repository: Debian ships an older client, and pg_dump refuses to dump a newer server
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends ca-certificates curl && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /usr/share/keyrings/postgresql.asc && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.asc] https://apt.postgresql.org/pub/repos/apt $DISTRO_NAME-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list

# Same packages as the production image (minus sqlite3), plus psql and an editor for credentials:edit.
# No libpq-dev: pg ships precompiled with libpq. No Node: bundlebun ships Bun as a gem.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=bind,source=Aptfile,target=/tmp/Aptfile \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
      build-essential git libyaml-dev pkg-config libvips \
      postgresql-client-$PG_MAJOR less vim-tiny \
      $(grep -Ev '^\s*#' /tmp/Aptfile | xargs)

# Run as the host user so files written to the bind-mounted project are not owned by root on Linux.
# --non-unique: the host GID may already exist in the image (e.g. 20 on macOS).
# Named volumes copy the owner of these directories when first mounted.
RUN groupadd --gid "$USER_GID" --non-unique app && \
    useradd --uid "$USER_UID" --gid "$USER_GID" --non-unique --create-home --shell /bin/bash app && \
    mkdir -p /usr/local/hist && \
    chown -R app:app /usr/local/bundle /usr/local/hist

ENV LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

USER app

CMD ["/bin/bash"]
