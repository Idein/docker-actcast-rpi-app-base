# CA distrust test certificates

These are public root certificates, copied from the existing
`idein/actcast-rpi-app-base:bullseye-3` image
(`sha256:93d46a745a8c5023e5009b46614e3baffd2cb659c9cb7df75422f03961fdde13`).
No private keys or generated certificates are used.

| File | Subject common name | SHA-256 fingerprint |
| --- | --- | --- |
| `emSign_ECC_Root_CA_-_G3.crt` | emSign ECC Root CA - G3 | `86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b` |
| `Comodo_AAA_Services_root.crt` | AAA Certificate Services | `d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4` |

Both certificates verify against the original image's CA bundle. After running
`block-emudhra-ca.sh`, both must fail with OpenSSL error 18 (untrusted self-signed
certificate), using either the CA bundle or the hashed certificate directory.
The fixtures remain available even after upstream packages remove these roots.

`cross-signed/` contains the six affected TLS intermediate certificates from
[Mozilla attachment 9664067](https://bugzilla.mozilla.org/attachment.cgi?id=9664067).
Their DER SHA-256 fingerprints match the list in
[Mozilla incident comment 2](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449#c2).
All six verify against the original bookworm-9 CA bundle. They must fail with
OpenSSL error 20 (unable to get local issuer certificate) after the mitigation.

This tests the public intermediate certificates and trust anchors, without
creating certificates using compromised private keys or connecting to a live
server using those keys.
