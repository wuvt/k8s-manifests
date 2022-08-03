.POSIX:

MANIFESTDIR := manifests
DHALL := dhall-to-yaml-ng
DHALLFLAGS := --documents

APPS := notecharlie
SECRETS := notecharlie

.PHONY: all
all: apps secrets

.PHONY: apps
apps: ${APPS:%=apps/%.yaml}

.PHONY: secrets
secrets: ${SECRETS:%=secrets/%.yaml}

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

.PHONY: clean
clean:
	rm -f ${APPS:%=apps/%.yaml}
	rm -f ${SECRETS:%=secrets/%.yaml}
	rm -rf ${MANIFESTDIR}

.PHONY: format
format:
	@find . -name \*.dhall -exec sh -c ' \
		dhall format < {} > {}.bak && \
		if cmp -s {} {}.bak; \
		then rm {}.bak; \
		else echo "formatted {}"; mv {}.bak {}; fi' \;

.PHONY: hash
hash:
	@find . -name \*.dhall -exec sh -c ' \
		printf "{} - "; dhall hash --file {}' \;

.SUFFIXES: .dhall .yaml
.dhall.yaml:
	${DHALL} ${DHALLFLAGS} --file $< > $@
