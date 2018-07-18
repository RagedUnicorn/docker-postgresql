#!/bin/sh

set -euo pipefail

if pg_isready; then
	exit 0
fi

exit 1
