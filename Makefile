.POSIX:
.SUFFIXES:

MANIFESTDIR := manifests
DHALL := dhall-to-yaml-ng
DHALLFLAGS := --documents

APPS := linx metadater notecharlie oauth2-proxy opensmtpd postgres \
postgres-bridge radiotextual retrofling slack-hooks trackman wuvt-site \
mediawiki fileserver burk postgres-oceangate
SECRETS := metadater notecharlie oauth2-proxy opensmtpd postgres radiotextual \
trackman-config-am trackman-nginx-am trackman-redis-am \
trackman-redis-cache-am wuvt-site-config-am wuvt-site-redis-am \
mediawiki

.PHONY: all
all: apps secrets rook

.PHONY: apps
apps: ${APPS:%=apps/%.yaml}

.PHONY: secrets
secrets: ${SECRETS:%=secrets/%.yaml}

.PHONY: rook
rook: rook/storageclass.yaml

.PHONY: manifests
manifests: all
	@mkdir -p ${MANIFESTDIR}
	@for APP in ${APPS} ; do \
		cp apps/$$APP.yaml ${MANIFESTDIR}/app.$$APP.yaml; \
		echo "cp apps/$$APP.yaml ${MANIFESTDIR}/app.$$APP.yaml"; \
	done
	@for SECRET in ${SECRETS} ; do \
		cp secrets/$$SECRET.yaml ${MANIFESTDIR}/secret.$$SECRET.yaml; \
		echo "cp secrets/$$SECRET.yaml ${MANIFESTDIR}/secret.$$SECRET.yaml"; \
	done
	@for ROOK in cluster operator storageclass ; do \
		cp rook/$$ROOK.yaml ${MANIFESTDIR}/rook.$$ROOK.yaml; \
		echo "cp rooks/$$ROOK.yaml ${MANIFESTDIR}/rook.$$ROOK.yaml"; \
	done

.PHONY: clean
clean:
	rm -f ${APPS:%=apps/%.yaml}
	rm -f ${SECRETS:%=secrets/%.yaml}
	rm -f rook/storageclass.yaml
	rm -rf ${MANIFESTDIR}

.PHONY: format
format:
	@find . -name \*.dhall -exec sh -c ' \
		dhall format < {} > {}.bak && \
		if cmp -s {} {}.bak; \
		then rm {}.bak; \
		else echo "formatted {}"; mv {}.bak {}; fi' \;

.PHONY: lint
lint:
	@find . -name \*.dhall -exec dhall lint --check {} +

.PHONY: hash
hash:
	@find . -name \*.dhall -exec sh -c ' \
		printf "{} - "; dhall hash --file {}' \;

.SUFFIXES: .dhall .yaml
.dhall.yaml:
	${DHALL} ${DHALLFLAGS} --file $< --output $@

lib.dhall: \
lib/app.dhall lib/networking.dhall lib/storage.dhall lib/typesUnion.dhall \
lib/util.dhall

.PHONY: secrets-encrypt
secrets-encrypt: secrets/k8s-secrets/secrets/*
	rm -f secrets/k8s-secrets/secrets.tar.gpg secrets/k8s-secrets/secrets.tar
	cd secrets/k8s-secrets && tar cf secrets.tar secrets/*
	gpg --batch --passphrase-file secrets/k8s-secrets/key.txt --symmetric secrets/k8s-secrets/secrets.tar
	rm -f secrets/k8s-secrets/secrets.tar

.PHONY: secrets.decrypt
secrets-decrypt: secrets/k8s-secrets/secrets.tar.gpg
	rm -rf secrets/k8s-secrets/secrets
	gpg --batch --passphrase-file secrets/k8s-secrets/key.txt --decrypt secrets/k8s-secrets/secrets.tar.gpg | tar xf - --directory=secrets/k8s-secrets/
