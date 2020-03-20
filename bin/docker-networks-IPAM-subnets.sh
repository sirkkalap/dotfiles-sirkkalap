#!/usr/bin/env bash

docker network ls -q | xargs docker network inspect --format='{{index .IPAM.Config}}'
