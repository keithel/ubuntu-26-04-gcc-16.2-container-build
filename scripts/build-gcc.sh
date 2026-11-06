#!/bin/bash
# Runs inside the container: fetch the gcc-16 source package and build C/C++ only.
set -euo pipefail

GCC_PKG=${GCC_PKG:-gcc-16}
LANGS=${LANGS:-c,c++}
KEEP_APT_CACHE=${KEEP_APT_CACHE:-0}

# Optional: keep downloaded .debs in /var/cache/apt/archives (bind-mounted by
# build.sh). The base image's docker-clean hook would otherwise delete them.
if [ "$KEEP_APT_CACHE" = 1 ]; then
  rm -f /etc/apt/apt.conf.d/docker-clean
  echo 'APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-debs
fi

RELEASE=$(. /etc/os-release && echo "$VERSION_CODENAME")

# Enable deb-src for the main ubuntu sources (deb822 on 24.04+, classic otherwise).
echo "deb-src http://archive.ubuntu.com/ubuntu/ $RELEASE main universe" \
  > /etc/apt/sources.list.d/gcc-src.list
echo "deb-src http://archive.ubuntu.com/ubuntu/ $RELEASE-updates main universe" \
  >> /etc/apt/sources.list.d/gcc-src.list

apt-get update
apt-get install -y --no-install-recommends build-essential devscripts dpkg-dev fakeroot
apt-get build-dep -y "$GCC_PKG"

mkdir -p /work/src /work/out
cd /work/src
# Always start from a pristine tree so stale/patched sources can't leak between runs.
rm -rf "${GCC_PKG}"-*/
ls ${GCC_PKG}_*.dsc >/dev/null 2>&1 || apt-get source --download-only "$GCC_PKG"
dpkg-source -x "$(ls ${GCC_PKG}_*.dsc | head -1)"
cd "$(ls -d ${GCC_PKG}-*/ | head -1)"

# lang=c,c++ is the packaging's own switch (see debian/rules.defs); no patching needed.
DEB_BUILD_OPTIONS="nodoc nocheck lang=$LANGS" \
  dpkg-buildpackage -b -us -uc -d -j"$(nproc)" 2>&1 | tee /work/out/build.log
cp ../*.deb /work/out/
