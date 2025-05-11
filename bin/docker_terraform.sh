#!/usr/bin/env bash
# Convenience wrapper for terraform cli.

docker run \
  --name grc_terraform \
  -v ./docs/terraform:/terraform:ro \
  --rm \
  hashicorp/terraform:latest
