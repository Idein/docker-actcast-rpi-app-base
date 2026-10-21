# The build tools need not use the same release as the target rootfs.
# RASPBIAN_VERSION in builder still selects bullseye for the Act image.
FROM debian:bookworm
LABEL maintainer "notogawa <n.ohkawa@idein.jp>"

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y qemu-user-static debootstrap ca-certificates xz-utils \
 && apt-get clean \
 && apt-get autoclean \
 && apt-get autoremove -y \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

COPY builder /root/builder
WORKDIR /root
CMD /bin/bash
