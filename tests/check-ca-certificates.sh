#!/bin/sh
set -eu

# OpenSSL 3 also loads a default CAstore; OpenSSL 1.1.1 has no such option.
no_castore=
if openssl verify -help 2>&1 | grep -q -- '-no-CAstore'; then
    no_castore=-no-CAstore
fi

test_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
result=$(mktemp)
trap 'rm -f "$result"' EXIT HUP INT TERM

if grep -Eq '^mozilla/(emSign_ECC_Root_CA_-_G3|Comodo_AAA_Services_root)\.crt$' /etc/ca-certificates.conf; then
    echo 'A blocked CA is still enabled in ca-certificates.conf' >&2
    exit 1
fi

for certificate in "$test_dir"/certificates/*.crt "$test_dir"/certificates/cross-signed/*.crt.pem; do
    case "$certificate" in
        *.crt.pem) expected_error='error 20 at 0 depth lookup: unable to get local issuer certificate' ;;
        *.crt) expected_error='error 18 at 0 depth lookup: self[- ]signed certificate' ;;
    esac
    # Check both the combined bundle and the OpenSSL hashed certificate directory.
    for store in bundle directory; do
        if [ "$store" = bundle ]; then
            set -- -CAfile /etc/ssl/certs/ca-certificates.crt -no-CApath
        else
            set -- -no-CAfile -CApath /etc/ssl/certs
        fi
        if openssl verify ${no_castore:+"$no_castore"} "$@" "$certificate" > "$result" 2>&1; then
            echo "Blocked CA is trusted by $store: $certificate" >&2
            exit 1
        fi
        # A parse error or a missing bundle must not be mistaken for distrust.
        if ! grep -Eq "$expected_error" "$result"; then
            cat "$result" >&2
            exit 1
        fi
        echo "Rejected by $store: $(basename "$certificate")"
    done
done

# Confirm that an unrelated root remains usable after rebuilding the store.
openssl verify ${no_castore:+"$no_castore"} -CAfile /etc/ssl/certs/ca-certificates.crt -no-CApath \
    /usr/share/ca-certificates/mozilla/Amazon_Root_CA_1.crt
openssl verify ${no_castore:+"$no_castore"} -no-CAfile -CApath /etc/ssl/certs \
    /usr/share/ca-certificates/mozilla/Amazon_Root_CA_1.crt
