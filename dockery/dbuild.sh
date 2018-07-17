#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description build script for docker-postgresql container

set -euo pipefail

WD="${PWD}"

# variable setup
DOCKER_POSTGRESQL_TAG="ragedunicorn/postgresql"
DOCKER_POSTGRESQL_NAME="postgresql"
DOCKER_POSTGRESQL_DATA_VOLUME="postgresql_data"

# get absolute path to script and change context to script folder
SCRIPTPATH="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "${SCRIPTPATH}"

echo "$(date) [INFO]: Building container: ${DOCKER_POSTGRESQL_NAME}"

# build postgresql container
docker build -t "${DOCKER_POSTGRESQL_TAG}" ../

# check if postgresql data volume already exists
docker volume inspect "${DOCKER_POSTGRESQL_DATA_VOLUME}" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "$(date) [INFO]: Reusing existing volume: ${DOCKER_POSTGRESQL_DATA_VOLUME}"
else
  echo "$(date) [INFO]: Creating new volume: ${DOCKER_POSTGRESQL_DATA_VOLUME}"
  docker volume create --name "${DOCKER_POSTGRESQL_DATA_VOLUME}" > /dev/null
fi

cd "${WD}"
