FROM ubuntu:zesty

LABEL com.ragedunicorn.maintainer="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
  com.ragedunicorn.version="1.0"

#     ____  ____  _____________________  ___________ ____    __
#    / __ \/ __ \/ ___/_  __/ ____/ __ \/ ____/ ___// __ \  / /
#   / /_/ / / / /\__ \ / / / / __/ /_/ / __/  \__ \/ / / / / /
#  / ____/ /_/ /___/ // / / /_/ / _, _/ /___ ___/ / /_/ / / /___
# /_/    \____//____//_/  \____/_/ |_/_____//____/\___\_\/_____/

# software versions
ENV \
  POSTGRESQL_MAJOR_VERSION=9.6 \
  POSTGRESQL_VERSION=9.6.2-1 \
  POSTGRESQL_COMMON_VERSION=179 \
  POSTGRESQL_CLIENT_COMMON_VERSION=179 \
  WGET_VERSION=1.18-2ubuntu1 \
  CA_CERTIFICATES_VERSION=20161130 \
  DIRMNGR_VERSION=2.1.15-1ubuntu7 \
  LOCALES_VERSION=2.24-9ubuntu2 \
  GOSU_VERSION=1.10

ENV \
  POSTGRESQL_USER=postgres \
  POSTGRESQL_APP_USER=app \
  POSTGRESQL_APP_PASSWORD=app \
  POSTGRESQL_DATA_DIR=/var/lib/postgresql/data \
  LANG=en_US.utf8 \
  PATH=/usr/lib/postgresql/${POSTGRESQL_MAJOR_VERSION}/bin:$PATH \
  PGDATA=${POSTGRESQL_DATA_DIR}

# explicitly set user/group IDs
RUN groupadd -r "${POSTGRESQL_USER}" --gid=999 && useradd -r -g "${POSTGRESQL_USER}" --uid=999 "${POSTGRESQL_USER}"

# install gosu
RUN \
  apt-get update && apt-get install -y --no-install-recommends \
    dirmngr="${DIRMNGR_VERSION}" \
    ca-certificates="${CA_CERTIFICATES_VERSION}" \
    wget="${WGET_VERSION}" && \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
  wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
  export GNUPGHOME && \
  GNUPGHOME="$(mktemp -d)" && \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
  rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc && \
  chmod +x /usr/local/bin/gosu && \
  gosu nobody true && \
  apt-get purge -y --auto-remove ca-certificates wget && \
  rm -rf /var/lib/apt/lists/*

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN \
  apt-get update && apt-get install -y --no-install-recommends \
  locales="${LOCALES_VERSION}" && \
  rm -rf /var/lib/apt/lists/* && \
  localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' "${POSTGRESQL_MAJOR_VERSION}" > /etc/apt/sources.list.d/pgdg.list

RUN \
  apt-get update && apt-get install -y --no-install-recommends \
    postgresql-common="${POSTGRESQL_COMMON_VERSION}" \
    postgresql-client-common="${POSTGRESQL_CLIENT_COMMON_VERSION}" \
    postgresql-"${POSTGRESQL_MAJOR_VERSION}"="${POSTGRESQL_VERSION}" \
    postgresql-contrib-"${POSTGRESQL_MAJOR_VERSION}"="${POSTGRESQL_VERSION}" && \
  sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \
  rm -rf /var/lib/apt/lists/*

# add init scripts for postgresql
COPY conf/user.sql /home/user.sql

# add launch script
COPY docker-entrypoint.sh /

RUN \
  chmod 755 /docker-entrypoint.sh

EXPOSE 5432

VOLUME ["${POSTGRESQL_DATA_DIR}"]

ENTRYPOINT ["/docker-entrypoint.sh"]
