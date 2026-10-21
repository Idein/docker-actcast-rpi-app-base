#!/bin/sh
set -eu

# Block the compromised eMudhra chain and the Sectigo cross-signing path.
# Keep disabled entries so subsequent ca-certificates upgrades retain the choice.
# https://bugzilla.mozilla.org/show_bug.cgi?id=2083449
sed -i \
    -e 's|^mozilla/emSign_ECC_Root_CA_-_G3\.crt$|!&|' \
    -e 's|^mozilla/Comodo_AAA_Services_root\.crt$|!&|' \
    /etc/ca-certificates.conf
update-ca-certificates --fresh
