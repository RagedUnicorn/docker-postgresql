#!/bin/sh
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description launch script for postgresql

# abort when trying to use unset variable
set -o nounset

postgresql_app_user="/run/secrets/com.ragedunicorn.postgresql.app_user"
postgresql_app_user_password="/run/secrets/com.ragedunicorn.postgresql.app_user_password"

function create_data_dir {
  echo "$(date) [INFO]: Creating data directory ${POSTGRESQL_DATA_DIR} and setting permissions"
  mkdir -p "${POSTGRESQL_DATA_DIR}"
  chmod -R 0700 "${POSTGRESQL_DATA_DIR}"
  chown -R "${POSTGRESQL_USER}":"${POSTGRESQL_GROUP}" "${POSTGRESQL_DATA_DIR}"
}

function create_run_dir {
  echo "$(date) [INFO]: Creating run directory ${POSTGRESQL_RUN_DIR} and setting permissions"
  mkdir -p "${POSTGRESQL_RUN_DIR}"
  chown -R "${POSTGRESQL_USER}":"${POSTGRESQL_GROUP}" "${POSTGRESQL_RUN_DIR}"
}

function init {
  # check for POSTGRESQL_DATA_DIR in data folder whether database was already initialized
  if [ ! -s "${POSTGRESQL_DATA_DIR}/PG_VERSION" ]; then
    echo "$(date) [INFO]: First time setup - running init script"

    if [ -f "${postgresql_app_user}" ] && [ -f "${postgresql_app_user_password}" ]; then
      echo "$(date) [INFO]: Found docker secrets - using secrets to setup postgresql"

      postgresql_app_user="$(cat ${postgresql_app_user})"
      postgresql_app_user_password="$(cat ${postgresql_app_user_password})"
    else
      echo "$(date) [INFO]: No docker secrets found - using environment variables"
      postgresql_app_user="${POSTGRESQL_APP_USER}"
      postgresql_app_user_password="${POSTGRESQL_APP_PASSWORD}"

      unset "${POSTGRESQL_APP_USER}"
      unset "${POSTGRESQL_APP_PASSWORD}"
    fi

    su -c "initdb --pgdata=${POSTGRESQL_DATA_DIR} --username=${POSTGRESQL_USER}" -s /bin/sh "${POSTGRESQL_USER}"

    # allow all users that are able to authenticate by password to connect
    { echo; echo "host all all 0.0.0.0/0 md5"; } >> "${POSTGRESQL_DATA_DIR}/pg_hba.conf"
    # allow postgres user only to login from localhost and without password
    { echo; echo "host all ${POSTGRESQL_USER} localhost trust"; } >> "${POSTGRESQL_DATA_DIR}/pg_hba.conf"

    # do not listen to external connections during setup. This helps while orchestarting
    # with other containers. They will only receive a response after the initialisation is finished.
    # Postgres documentation - listen_addresses (string)
    # The value takes the form of a comma-separated list of host names and/or numeric IP addresses.
    # ... If the list is empty, the server does not listen on any IP interface at all ...
    su -c "pg_ctl -D ${POSTGRESQL_DATA_DIR} -o '-c listen_addresses= ' -w start" -s /bin/sh "${POSTGRESQL_USER}"

    echo "$(date) [INFO]: Setup app user"
    # setup default app-user
    sed -e "s/{{password}}/${postgresql_app_user_password}/g" \
      -e "s/{{user}}/${postgresql_app_user}/g" /home/user.sql | psql -U ${POSTGRESQL_USER}

    sed -ri 's/#(listen_addresses) = .*$/\1 = '\''*'\''/' /var/lib/postgresql/data/postgresql.conf

    su -c "pg_ctl -D ${POSTGRESQL_DATA_DIR} -m fast -w stop" -s /bin/sh "${POSTGRESQL_USER}"
    echo "$(date) [INFO]: Stopping postgres"
  fi

  echo "$(date) [INFO]: Starting postgres..."
  exec su-exec ${POSTGRESQL_USER} postgres -D "${POSTGRESQL_DATA_DIR}"
}

create_data_dir
create_run_dir
init
