# gcc-16 release build for Ubuntu 26.04 (C/C++ only)

Ubuntu 26.04's `gcc-16` binary package is a pre-release snapshot
(`16-20260322-1ubuntu1`). This project rebuilds Ubuntu's `gcc-16` **source**
package (16.2.0) inside a Docker container and produces `.deb` files for the
released compiler. Only C and C++ are built.

## Requirements

- Docker
- Several GB of free disk space and a fair amount of time (a full GCC build)

## Build

    ./build.sh

This builds the `gcc-builder` image, then runs it with `gcc-build/` mounted as `/work`
(`src/` = source + build tree, `out/` = results: the `.deb` files and `build.log`).

### Debugging / repeated runs: keep the apt cache

By default nothing is cached on the host. If you are iterating and re-running the
build, avoid re-downloading ~400 packages each time:

    KEEP_APT_CACHE=1 ./build.sh

This additionally mounts `apt-cache/` at `/var/cache/apt/archives` and disables the base
image's `docker-clean` hook (at run time, so no image rebuild is needed). Delete
`apt-cache/` (root-owned; use `sudo`) when done.

What the build does (`scripts/build-gcc.sh`):

1. Enables `deb-src`, runs `apt-get build-dep gcc-16`.
2. Unpacks a **fresh** source tree from the `.dsc` every run (no stale state).
3. Runs `dpkg-buildpackage -b` with `DEB_BUILD_OPTIONS="nodoc nocheck lang=c,c++"`.
   `lang=` is the packaging's own language switch; the test suite is skipped.

Settings can be overridden with environment variables (add `-e VAR=value` to the
`docker run` in `build.sh`; `KEEP_APT_CACHE` is already passed through): `LANGS` (default `c,c++`), `GCC_PKG` (default `gcc-16`).

Notes:
- The container writes files as root, so `gcc-build/` contents are root-owned;
  use `sudo` to delete them.
- The apt cache needs `KEEP_APT_CACHE=1` because the base image's
  `/etc/apt/apt.conf.d/docker-clean` otherwise deletes every `.deb` after install.
- Don't run two builds at once; they share the apt cache lock.

## Install

### Do NOT `apt install ./*.deb` on a multiarch system

The snapshot `gcc-16` runtime packages are pinned to exact versions and are
installed for both `amd64` and `i386` on many machines (e.g. with Steam). Only
`amd64` is built here, so apt resolves the conflict by **removing hundreds of
`:i386` packages**. Check with `apt-get install -s ...` before trying it.

### Recommended: side-by-side install in `/opt/gcc-16.2`

This extracts the debs into a private prefix without touching dpkg's database:

    cd gcc-build/out
    sudo mkdir -p /opt/gcc-16.2
    for p in cpp-16 cpp-16-x86-64-linux-gnu g++-16 g++-16-x86-64-linux-gnu \
             gcc-16 gcc-16-x86-64-linux-gnu gcc-16-base libgcc-16-dev \
             libstdc++-16-dev libgcc-s1 libstdc++6 libgomp1 libatomic1 \
             libasan8 libubsan1 libquadmath0 libitm1 liblsan0 libtsan2 \
             libhwasan0 libcc1-0; do
      sudo dpkg-deb -x ${p}_16.2.0-3ubuntu1_amd64.deb /opt/gcc-16.2
    done

Use it by putting it on `PATH`:

    export PATH=/opt/gcc-16.2/usr/bin:$PATH
    g++-16 --version        # g++-16 (Ubuntu 16.2.0-3ubuntu1) 16.2.0

(The version suffix in the `.deb` filenames may differ if the source package is updated.)

### Runtime libraries

Programs built with this compiler use the **system** `libstdc++`/`libgcc_s`
(the snapshot) unless told otherwise, and may miss newer symbols. To use the
16.2 runtime, link with an rpath:

    g++-16 foo.cpp -o foo -Wl,-rpath,/opt/gcc-16.2/usr/lib/x86_64-linux-gnu

### Uninstall

    sudo rm -rf /opt/gcc-16.2

## Layout

    Dockerfile            build image (stock Ubuntu 26.04)
    build.sh              builds the image and runs the build
    scripts/build-gcc.sh  runs inside the container
    apt-cache/            optional host-side apt cache, KEEP_APT_CACHE=1 only (git-ignored)
    gcc-build/            host-side sources and output (git-ignored)
