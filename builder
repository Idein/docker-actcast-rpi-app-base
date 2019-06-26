#!/bin/bash
set -xue

readonly RASPBIAN_VERSION=${RAPBIAN_VERSION:-buster}
readonly RASPBIAN_MIRROR=${RASPBIAN_MIRROR:-'http://archive.raspbian.org/raspbian'}
readonly TMP_DIR=$(mktemp -d /tmp/docker-builder.XXXXXXXXXX)
readonly ROOTFS_DIR=$TMP_DIR/rootfs

# debootstrap
wget http://archive.raspbian.org/raspbian.public.key -O - | gpg --import -
debootstrap \
  --foreign \
  --variant=minbase \
  --arch=armhf \
  --verbose \
  --keyring=/root/.gnupg/pubring.kbx \
  --include=ca-certificates \
  $RASPBIAN_VERSION $ROOTFS_DIR $RASPBIAN_MIRROR
cp /usr/bin/qemu-arm-static ${ROOTFS_DIR}/usr/bin/
chroot ${ROOTFS_DIR} ./debootstrap/debootstrap --second-stage --no-check-gpg

# add keys
wget http://archive.raspbian.org/raspbian.public.key           -O - | chroot ${ROOTFS_DIR} apt-key add -
wget http://archive.raspberrypi.org/debian/raspberrypi.gpg.key -O - | chroot ${ROOTFS_DIR} apt-key add -

# video group required to use VC4 GPGPU
# see. https://github.com/Idein/actcast/issues/2269#issuecomment-463014012
chroot ${ROOTFS_DIR} usermod -aG video root

# audio group required to use sound devices
chroot ${ROOTFS_DIR} usermod -aG audio root

# prevent starting services when "apt install"
cat > "${ROOTFS_DIR}/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod +x "${ROOTFS_DIR}/usr/sbin/policy-rc.d"

# cleanup
chroot ${ROOTFS_DIR} apt-get clean

# Docker images habe no kernels installed
rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/01autoremove-kernels"

# schedule cleanup
cat > "${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-clean" <<'EOF'
DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };
APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
EOF

# remove apt-cache translations
cat > "${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-no-languages" <<'EOF'
Acquire::Languages "none";
EOF

# compress indexes
cat > "${ROOTFS_DIR}/etc/apt/apt.conf.d/docker-gzip-indexes" <<'EOF'
Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
EOF

# set apt source
cat > "${ROOTFS_DIR}/etc/apt/sources.list" <<EOF
deb http://archive.raspbian.org/raspbian ${RASPBIAN_VERSION} main firmware
EOF

chroot ${ROOTFS_DIR} bash -c 'apt-get update && apt-get dist-upgrade -y'
rm -rf ${ROOTFS_DIR}/var/lib/apt/lists/*
cat > "${ROOTFS_DIR}/etc/apt/sources.list.d/raspi.list" <<EOF
deb http://archive.raspberrypi.org/debian ${RASPBIAN_VERSION} main
EOF

rm -rf "${ROOTFS_DIR}/dev" "${ROOTFS_DIR}/proc"
mkdir -p "${ROOTFS_DIR}/dev" "${ROOTFS_DIR}/proc"

# public dns
mkdir -p "${ROOTFS_DIR}/etc"
cat > "${ROOTFS_DIR}/etc/resolv.conf" <<'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# exclude docs
cat > "${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/01_nodoc" <<'EOF'
path-exclude /usr/share/doc/*
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
EOF

# exclude locales
cat > "${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/01_nolocales" <<'EOF'
path-exclude /usr/share/locale/*
path-include /usr/share/locale/en*
EOF

# configure apt
cat > "${ROOTFS_DIR}/etc/apt/apt.conf.d/01_buildconfig" <<'EOF'
APT::Get::Assume-Yes "true";
APT::Install-Recommends "0";
APT::Install-Suggests "0";
quiet "true";
EOF

# disabl cache
cat > "${ROOTFS_DIR}/etc/apt/apt.conf.d/02_nocache" <<'EOF'
Dir::Cache {
  srcpkgcache "";
  pkgcache "";
}
EOF

mkdir -p /usr/share/man/man1

find "${ROOTFS_DIR}/usr/share/doc" -depth -type f ! -name copyright -exec rm {} \; | true
find "${ROOTFS_DIR}/usr/share/doc" -empty -exec rmdir {} \; | true
find "${ROOTFS_DIR}/usr/share/locale/"* -depth -type d ! -name en* -exec rm -rf {} \; | true
rm -rf "${ROOTFS_DIR}/usr/share/man/*" "${ROOTFS_DIR}/usr/share/groff/*" "${ROOTFS_DIR}/usr/share/info/*"
rm -rf "${ROOTFS_DIR}/usr/share/lintian/*" "${ROOTFS_DIR}/usr/share/linda/*" "${ROOTFS_DIR}/var/cache/man/*"

# packaging
tar --numeric-owner -caf "${TMP_DIR}/rootfs.tar.xz" -C "${ROOTFS_DIR}" --transform='s,^./,,' .
mv "${TMP_DIR}/rootfs.tar.xz" /root/
