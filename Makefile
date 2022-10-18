.POSIX:

MANIFESTDIR := manifests
DHALL := dhall-to-yaml-ng
DHALLFLAGS := --documents

APPS := linx notecharlie postgres
SECRETS := notecharlie postgres

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
	@for ROOK in cluster common crds operator storageclass toolbox ; do \
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
.dhall.yaml: lib.dhall Prelude.dhall kubernetes.dhall rook.dhall \
rook/blockStorage.dhall rook/objectStorage.dhall
	${DHALL} ${DHALLFLAGS} --file $< --output $@

lib.dhall: \
lib/app.dhall lib/config.dhall lib/env.dhall lib/ingress.dhall \
lib/services.dhall lib/storage.dhall lib/typesUnion.dhall lib/util.dhall \
lib/volumes.dhall
