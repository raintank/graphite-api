#! /usr/bin/env bash
set -xe

export VERSION=1.1.3

apt-get -y install build-essential python-dev python-virtualenv libffi-dev

rm -rf build

cd $(dirname $0)

graphite_api_branch="master"
graphite_kairoadb_branch="master"
package_destination="./"

OPTIND=1
while getopts "a:k:p:" opt; do
    case $opt in
    a) graphite_api_branch=$OPTARG
       ;;
    k) graphite_kairoadb_branch=$OPTARG
       ;;
    p) package_destination=$OPTARG
       ;;
    esac
done

if [ -d build ]; then
	rm -r build/
fi

mkdir -p build/usr/share/python

virtualenv build/usr/share/python/graphite
build/usr/share/python/graphite/bin/pip install -U pip distribute
build/usr/share/python/graphite/bin/pip uninstall -y distribute

build/usr/share/python/graphite/bin/pip install git+https://github.com/raintank/graphite-api.git@$graphite_api_branch
build/usr/share/python/graphite/bin/pip install graphite-api[sentry,cyanite] gunicorn==18.0

find build ! -perm -a+r -exec chmod a+r {} \;

cd build/usr/share/python/graphite
sed -i "s/'\/bin\/python'/\('\/bin\/python','\/bin\/python2'\)/g" lib/python2.7/site-packages/virtualenv_tools.py
./bin/virtualenv-tools --update-path /usr/share/python/graphite
cd -

find build -iname *.pyc -exec rm {} \;
find build -iname *.pyo -exec rm {} \;

cp -a conf/etc build


sudo fpm \
	-t deb -s dir -C build -n graphite-api-rt -v $VERSION \
	--iteration `date +%s` \
	--deb-default conf/etc/default/graphite-api \
	--deb-init conf/etc/init.d/graphite-api \
	--deb-user root \
	--deb-group root \
	--config-files /etc/graphite-api.yaml \
	--config-files /etc/init.d/graphite-api \
	--config-files /etc/default/graphite-api \
	-d libcairo2 \
	-d "libffi5 | libffi6" \
	-d adduser \
	-d python \
	--after-install conf/post-install \
	--before-remove conf/pre-remove \
	--after-remove conf/post-remove \
	--url https://github.com/raintank/graphite-api \
	--description 'Graphite-web, without the interface. Just the rendering HTTP API. (raintank fork)' \
	--license 'Apache 2.0' \
  ${package_destination}
