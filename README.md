# A simple, OpenSSL-based public key infrastructure for SMIME certificates.

Configuration based on
https://pki-tutorial.readthedocs.io/en/latest/simple/index.html, but leaving out
the intermediate subordinate CA and tinkering around with extensions and
policies.

## Generate a CSR

To generate a default SMIME CSR, just run `make`.  To specify the file name of
the csr, enter the slightly more verbose

```sh
make certs/your-cert-name-here.csr
```

Then send the CSR to the one playing Root CA.  Put the returned certificate file
`your-cert-name-here.crt` into the `certs` directory, and generate a PKCS#12 file
via

```sh
make certs/your-cert-name-here.p12
```

Then import the `p12` file via `gpgsm --import certs/your-cert-name-here.p12`.

Note that this generates classical 4096bit RSA keys and certificates, which
should be supported by a wide range of mail clients.  If you want to generated
newer RSA-PSS certificates, prefix your certificate name with `rsapss_` like so:

```sh
make certs/rsapss_your-cert-name-here.p12
```

Note that support for checking RSA-PSS signatures might not be that widespread,
though.

## Playing Root CA

If you want to be the root, run

```sh
make root-ca/ca.crt
```

The root certificate will always be a 4096bit RSA certificate.

You may want to change the PKI name (both in [root-ca.conf](config/root-ca.conf)
and [smime-req.conf](config/smime-req.conf)) and the Authority Information
Access URI in the Root CA configuration.

If you are going to make use of CRLs and want to make them available at an URI,
change the `crl_distribution_point` variable defined in the `root_ca` section of
[root-ca.conf](config/root-ca.conf).

To sign CSRs, put those into the `certs` directory and run

```sh
make certs/csr-name.crt
```

send the resulting `csr-name.crt` to the requester.

To generate CRLs, run

```sh
make root-ca/ca.crl
```

Revoke certificates by

```sh
openssl ca -config config/root-ca.conf -revoke root-ca/${CERT_SERIAL}.pem -crl_reason superseded
```

where `CERT_SERIAL` contains the serial number of the certificate that should be
revoked.  Also adapt the CRL reason according to your needs.  Regenerate the CRL
afterwards and publish it accordingly.

## License

These files are licensed under the MIT license.  This work is based on
https://pki-tutorial.readthedocs.io/en/latest/simple/index.html,
Stefan H. Holek, 2014.
