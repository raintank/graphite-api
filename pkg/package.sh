#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

: ${NAME:="graphite-api-rt"}
: ${BUILD_DIR:="${DIR}/build"}
VERSION="1.0.1"
ARCH="$(uname -m)"
PACKAGE_NAME="${DIR}/artifacts/NAME-VERSION-ITERATION_ARCH.deb"
ITERATION=`date +%s`
TAG="pkg-${VERSION}-${ITERATION}"

git tag $TAG
git push --tags

fpm \
  -t deb -s dir -C ${BUILD_DIR} -n ${NAME} -v $VERSION \
  --iteration ${ITERATION} \
  --deb-default ${DIR}/config/ubuntu/trusty/etc/default/graphite-api \
  --deb-init ${DIR}/config/ubuntu/trusty/etc/init.d/graphite-api \
  --config-files /etc/graphite-api.yaml \
  -d libcairo2 \
  -d "libffi5 | libffi6" \
  --after-install ${DIR}/debian/post-install \
  --before-remove ${DIR}/debian/pre-remove \
  --after-remove ${DIR}/debian/post-remove \
  --url https://github.com/raintank/graphite-api \
  --description 'Graphite-web, without the interface. Just the rendering HTTP API. (raintank fork)' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} usr etc
