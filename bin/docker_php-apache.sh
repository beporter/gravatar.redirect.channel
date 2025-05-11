#!/usr/bin/env bash
# Launch a local docker container for testing.

echo 'Run `docker stop grc_apache` to terminate.'

docker build -t grc:local .
docker run -itd \
  --name grc_apache \
  -v ./docs:/var/www/html:ro \
  -p 8080:80 \
  --rm \
  grc:local

open http://localhost:8080
