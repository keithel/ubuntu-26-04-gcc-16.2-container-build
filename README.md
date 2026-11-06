# gcc-16 release build for Ubuntu 26.04 (C/C++ only)

Rebuilds Ubuntu's `gcc-16` source package (16.2.0) in a container, because the
`gcc-16` binary package in the archive is a pre-release snapshot.
Only C and C++ are built, via the packaging's `lang=c,c++` build option.

## Usage

    ./build.sh

- `gcc-build/` (host) is mounted as `/work`: sources in `src/`, results in `out/` (`.deb` files + `build.log`).
- `apt-cache/` (host) is mounted as `/var/cache/apt/archives`, so re-runs don't re-download packages.
  The Dockerfile removes the base image's `docker-clean` apt hook, which otherwise deletes every `.deb`.

Environment overrides (pass with `docker run -e`, or edit `build.sh`): `LANGS` (default `c,c++`), `GCC_PKG` (default `gcc-16`).

Install the result with `sudo apt install ./gcc-build/out/{gcc,g++,cpp,libgcc,libstdc++}*16*.deb` (resolve dependencies as needed).
