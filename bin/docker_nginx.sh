#!/usr/bin/env bash
# Launch a local nginx docker container for testing.

docker run \
  --name grc_nginx \
  -v ./docs/nginx/gravatarize.conf:/etc/nginx/conf.d/gravatarize.conf:ro \
  -v ./docs/nginx/gravatarize.js:/etc/nginx/conf.d/gravatarize.js:ro \
  -v ./docs:/usr/share/nginx/html:ro \
  -p 8080:80 \
  --rm \
  nginx:stable

