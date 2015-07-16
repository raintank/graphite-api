#! /usr/bin/env bash
set -xe

export VERSION=1.0.1

branch=`git rev-parse --abbrev-ref HEAD`

mkdir -p build/usr/share/python
virtualenv build/usr/share/python/graphite
build/usr/share/python/graphite/bin/pip install -U pip distribute
build/usr/share/python/graphite/bin/pip uninstall -y distribute

build/usr/share/python/graphite/bin/pip install git+https://github.com/raintank/graphite-api.git@$branch
build/usr/share/python/graphite/bin/pip install graphite-api[sentry,cyanite] gunicorn==18.0
build/usr/share/python/graphite/bin/pip install git+https://github.com/raintank/graphite-kairosdb.git
build/usr/share/python/graphite/bin/pip install eventlet
build/usr/share/python/graphite/bin/pip install statsd
build/usr/share/python/graphite/bin/pip install Flask-Cache
build/usr/share/python/graphite/bin/pip install cassandra-driver
build/usr/share/python/graphite/bin/pip install blist

find build ! -perm -a+r -exec chmod a+r {} \;

cd build/usr/share/python/graphite
virtualenv-tools --update-path /usr/share/python/graphite
cd -

find build -iname *.pyc -exec rm {} \;
find build -iname *.pyo -exec rm {} \;

cp -a conf/etc build

sudo fpm \
	-t deb -s dir -C build -n graphite-api-rt -v $VERSION \
	--iteration `date +%s` \
	--deb-default conf/etc/default/graphite-api \
	--deb-init conf/etc/init.d/graphite-api \
	--config-files /etc/graphite-api.yaml \
	--config-files /etc/init.d/graphite-api \
	--config-files /etc/default/graphite-api \
	-d libcairo2 \
	-d "libffi5 | libffi6" \
	--after-install conf/post-install \
	--before-remove conf/pre-remove \
	--after-remove conf/post-remove \
	--url https://github.com/raintank/graphite-api \
	--description 'Graphite-web, without the interface. Just the rendering HTTP API. (raintank fork)' \
	--license 'Apache 2.0' \
	.
