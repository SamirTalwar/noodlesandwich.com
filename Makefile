SHELL := /bin/bash
PATH := $(PWD)/node_modules/.bin:$(PATH)

TAG = samirtalwar/noodlesandwich.com
ifdef OFFLINE
BUILD_ARGS =
else
BUILD_ARGS = --pull
endif

PRESENTATION_INPUT_FILES = $(wildcard src/presentations/*.elm)
PRESENTATION_NAMES = $(basename $(notdir $(PRESENTATION_INPUT_FILES)))
PRESENTATION_OUTPUT_FILES = $(addprefix build/assets/talks/, \
								$(addsuffix /presentation.js, $(PRESENTATION_NAMES)))
ELM_DEPENDENCIES = $(wildcard src/NoodleSandwich/*.elm) $(wildcard src/NoodleSandwich/**/*.elm) \
				   elm-stuff/packages

build: Dockerfile node_modules gulpfile.js $(wildcard src/**/*) $(PRESENTATION_OUTPUT_FILES)
	gulp

.PHONY: docker-build
docker-build: build
	docker build $(BUILD_ARGS) --tag=$(TAG) .

.PHONY: run
run:
	docker run \
		--rm \
		--interactive --tty \
		--publish=80:80 \
		--env=DOMAIN=localhost \
		--env=PORT=80 \
		--volume=$(PWD)/build:/usr/share/nginx/html \
		samirtalwar/noodlesandwich.com

.PHONY: clean
clean:
	rm -rf build/*
	rm -rf elm-stuff/build-artifacts

.PHONY: check
check: lint

.PHONY: lint
lint: node_modules
	yarn run lint

.PHONY: push
push: clean build check docker-build
	@ [[ -z "$$(git status --porcelain)" ]] || { \
		echo >&2 'Cannot push with a dirty working tree.'; \
		exit 1; \
	}
	@ [[ "$$(git name)" == 'master' ]] || { \
		echo >&2 'You must run this command from the `master` branch.'; \
		exit 1; \
	}
	docker push $(TAG)
	git push $(GIT_FLAGS)

build/assets/talks/%/presentation.js: src/presentations/%.elm $(ELM_DEPENDENCIES)
	elm make --warn --output=$@ $<

node_modules: package.json
	yarn install --frozen-lockfile
	npm rebuild
	touch node_modules

elm-stuff/packages: elm-package.json node_modules
	elm package install -y
