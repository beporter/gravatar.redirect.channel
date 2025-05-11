#!/usr/bin/env bash
# Point your vscode extensions at this script.
# It will proxy php execution into the docker container.

docker run --rm -t -v $(pwd):/var/www/html grc:local php "$@"
