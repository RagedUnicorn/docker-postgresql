#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description script for attaching to running docker-postgresql container

# abort when trying to use unset variable
set -o nounset

WD="${PWD}"

# variable setup
DOCKER_POSTGRESQL_NAME="postgresql"

# get absolute path to script and change context to script folder
SCRIPTPATH="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "${SCRIPTPATH}"

echo "$(date) [INFO]: attaching to container ${DOCKER_POSTGRESQL_NAME}. To detach from the container use Ctrl-p Ctrl-q"
# attach to container
docker attach "${DOCKER_POSTGRESQL_NAME}"

cd "${WD}"
