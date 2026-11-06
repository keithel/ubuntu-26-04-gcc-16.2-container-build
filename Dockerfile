# syntax=docker/dockerfile:1
ARG UBUNTU_RELEASE=stonking
FROM ubuntu:${UBUNTU_RELEASE}

ENV DEBIAN_FRONTEND=noninteractive

# The Ubuntu base image ships /etc/apt/apt.conf.d/docker-clean, which deletes
# every downloaded .deb after install. Remove it and tell apt to keep packages,
# so a bind-mounted /var/cache/apt/archives actually accumulates .debs.
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
 && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-debs \
 && echo 'APT::Keep-Downloaded-Packages "true";' >> /etc/apt/apt.conf.d/01keep-debs

COPY scripts/build-gcc.sh /usr/local/bin/build-gcc.sh
RUN chmod +x /usr/local/bin/build-gcc.sh

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/build-gcc.sh"]
