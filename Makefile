.POSIX:
.DEFAULT: all
.PHONY: all distclean

all: certs/smime-test.csr

root-ca/ca.crt:
	mkdir -p root-ca/private root-ca/db certs
	chmod 700 root-ca/private
	touch root-ca/db/ca.db
	touch root-ca/db/ca.db.attr
	echo 01 > root-ca/db/ca.crt.srl
	echo 01 > root-ca/db/ca.crl.srl
	openssl req -new \
                    -config config/root-ca.conf \
                    -out root-ca/ca.csr \
                    -keyout root-ca/private/ca.key
	openssl ca -selfsign \
	           -config config/root-ca.conf \
	           -in root-ca/ca.csr \
	           -out root-ca/ca.crt \
	           -extensions root_ca_ext

# Make sure CRLs are regenerated when the CA database changes by including the
# file as a prerequisite in the recipe
root-ca/ca.crl: root-ca/ca.crt root-ca/db/ca.db
	openssl ca -gencrl \
	           -config config/root-ca.conf \
	| openssl crl -in - \
	           -out root-ca/ca.crl \
	           -outform der

certs/rsapss_%.csr certs/rsapss_%.key:
	mkdir -p certs/
	openssl genpkey -algorithm RSA-PSS \
	                -out certs/rsapss_$*.key \
	                -aes256 \
	                -pkeyopt rsa_keygen_bits:4096
	openssl req -new \
	            -key certs/rsapss_$*.key \
	            -config config/smime-req.conf \
	            -out certs/rsapss_$*.csr

certs/%.csr certs/%.key:
	mkdir -p certs/
	openssl req -new \
	            -config config/smime-req.conf \
	            -out certs/$*.csr \
	            -keyout certs/$*.key

certs/%.crt: certs/%.csr
	openssl ca -config config/root-ca.conf \
	           -in certs/$*.csr \
	           -out certs/$*.crt \
	           -days 1780 \
	           -extensions email_ext \
	           -policy email_pol

certs/%.p12: certs/%.crt certs/%.key
	openssl pkcs12 -export \
	               -inkey certs/$*.key \
	               -in certs/$*.crt \
	               -certfile root-ca/ca.crt \
	               -out certs/$*.p12

distclean:
	@rm -rfv root-ca certs
