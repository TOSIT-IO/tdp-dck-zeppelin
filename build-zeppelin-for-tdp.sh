#!/bin/bash

VERSION_TAG=0

DOCKER_BUILDKIT=1 docker build --progress=plain \
-t zeppelin:0.10.0-tdp-v${VERSION_TAG} \
--no-cache \
--squash \
-f Dockerfile \
. \
$@

#docker save -o zeppelin-0.10.0-tdp-v${VERSION_TAG}.tar zeppelin:0.10.0-tdp-v${VERSION_TAG}
