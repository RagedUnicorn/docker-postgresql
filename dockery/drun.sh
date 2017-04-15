#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description run script for docker-postgresql container

# abort when trying to use unset variable
set -o nounset

# variable setup
DOCKER_POSTGRESQL_TAG="com.ragedunicorn/postgresql"
DOCKER_POSTGRESQL_NAME="postgresql"
DOCKER_POSTGRESQL_DATA_VOLUME="postgresql_data"
DOCKER_POSTGRESQL_ID=0

# get absolute path to script and change context to script folder
SCRIPTPATH="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "${SCRIPTPATH}"

# check if there is already an image created
docker inspect ${DOCKER_POSTGRESQL_NAME} &> /dev/null

if [ $? -eq 0 ]; then
  # start container
  docker start "${DOCKER_POSTGRESQL_NAME}"
else
  ## run image:
  # -d run in detached mode
  # --name define a name for the container(optional)
  DOCKER_POSTGRESQL_ID=$(docker run \
  -v postgresql_data:/var/lib/postgresql \
  -dit \
  --name "${DOCKER_POSTGRESQL_NAME}" "${DOCKER_POSTGRESQL_TAG}")
fi

if [ $? -eq 0 ]; then
  # print some info about containers
  echo "$(date) [INFO]: Container info:"
  docker inspect -f '{{ .Config.Hostname }} {{ .Name }} {{ .Config.Image }} {{ .NetworkSettings.IPAddress }}' ${DOCKER_POSTGRESQL_NAME}
else
  echo "$(date) [ERROR]: Failed to start container - ${DOCKER_POSTGRESQL_NAME}"
fi
