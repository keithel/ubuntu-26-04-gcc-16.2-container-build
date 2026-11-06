#!/bin/bash
# Build the image and run the GCC build. Results go to ./gcc-build/out.
#
#   ./build.sh                   normal build, nothing cached on the host
#   KEEP_APT_CACHE=1 ./build.sh  also keep downloaded .debs in ./apt-cache,
#                                for debugging / repeated runs
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p gcc-build
args=(-v "$PWD/gcc-build:/work")
if [ "${KEEP_APT_CACHE:-0}" = 1 ]; then
  mkdir -p apt-cache
  args+=(-v "$PWD/apt-cache:/var/cache/apt/archives" -e KEEP_APT_CACHE=1)
fi
docker build -t gcc-builder .
docker run --rm -it "${args[@]}" gcc-builder "$@"
