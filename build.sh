#!/bin/bash
# Build the image and run the GCC build, using host dirs for apt cache and output.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p apt-cache gcc-build
docker build -t gcc-builder .
docker run --rm -it \
  -v "$PWD/gcc-build:/work" \
  -v "$PWD/apt-cache:/var/cache/apt/archives" \
  gcc-builder "$@"
