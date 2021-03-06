FROM alpine:3.12.0

LABEL com.ragedunicorn.maintainer="Michael Wiesendanger <michael.wiesendanger@gmail.com>"

#     ____  ____  _____________________  ___________ ____    __
#    / __ \/ __ \/ ___/_  __/ ____/ __ \/ ____/ ___// __ \  / /
#   / /_/ / / / /\__ \ / / / / __/ /_/ / __/  \__ \/ / / / / /
#  / ____/ /_/ /___/ // / / /_/ / _, _/ /___ ___/ / /_/ / / /___
# /_/    \____//____//_/  \____/_/ |_/_____//____/\___\_\/_____/

# image args
ARG POSTGRESQL_USER=postgres
ARG POSTGRESQL_GROUP=postgres
ARG POSTGRESQL_APP_USER=app
ARG POSTGRESQL_APP_PASSWORD=app

# software versions
ENV \
  POSTGRESQL_VERSION=12.3-r2 \
  SU_EXEC_VERSION=0.2-r1

ENV \
  POSTGRESQL_USER="${POSTGRESQL_USER}" \
  POSTGRESQL_GROUP="${POSTGRESQL_GROUP}" \
  POSTGRESQL_APP_USER="${POSTGRESQL_APP_USER}" \
  POSTGRESQL_APP_PASSWORD="${POSTGRESQL_APP_PASSWORD}" \
  POSTGRESQL_DATA_DIR=/var/lib/postgresql/data \
  POSTGRESQL_RUN_DIR=/run/postgresql \
  POSTGRES_HOME=/var/lib/postgresql \
  LANG=en_US.utf8 \
  PGDATA=/var/lib/postgresql/data

RUN \
  set -ex; \
  apk add --no-cache \
    su-exec="${SU_EXEC_VERSION}" \
    postgresql="${POSTGRESQL_VERSION}"

# alpine includes "postgres" user/group in base install however the homedirectory
# is not created by default
RUN set -ex; \
  mkdir -p "${POSTGRES_HOME}"; \
  chown -R "${POSTGRESQL_USER}":"${POSTGRESQL_GROUP}" "${POSTGRES_HOME}"; \
  mkdir -p "${POSTGRESQL_DATA_DIR}"; \
  chown -R "${POSTGRESQL_USER}":"${POSTGRESQL_GROUP}" "${POSTGRESQL_DATA_DIR}"

# add init scripts for postgresql
COPY config/user.sql /home/user.sql

# add healthcheck script
COPY docker-healthcheck.sh /

# add launch script
COPY docker-entrypoint.sh /

RUN \
  chmod 755 /docker-entrypoint.sh && \
  chmod 755 /docker-healthcheck.sh

EXPOSE 5432

VOLUME ["${POSTGRESQL_DATA_DIR}"]

ENTRYPOINT ["/docker-entrypoint.sh"]
