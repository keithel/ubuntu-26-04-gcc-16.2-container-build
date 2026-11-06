# syntax=docker/dockerfile:1
ARG UBUNTU_RELEASE=stonking
FROM ubuntu:${UBUNTU_RELEASE}

ENV DEBIAN_FRONTEND=noninteractive

# Stock apt behaviour (docker-clean deletes .debs after install). Caching of
# downloaded packages is a run-time opt-in: see KEEP_APT_CACHE in build.sh.

COPY scripts/build-gcc.sh /usr/local/bin/build-gcc.sh
RUN chmod +x /usr/local/bin/build-gcc.sh

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/build-gcc.sh"]
