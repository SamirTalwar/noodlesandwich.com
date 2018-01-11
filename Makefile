SHELL := /bin/bash
PATH := $(PWD)/node_modules/.bin:$(PATH)

SITE_HOST = noodlesandwich.com
SITE_URL = $(shell jq -r '.url' < dat.json)

TAG = samirtalwar/noodlesandwich.com
BUILD_TAG = samirtalwar/noodlesandwich.com-build

build: build.Dockerfile Dockerfile node_modules gulpfile.js $(wildcard src/**/*) build/presentations/99-problems.js
	gulp
	docker build --pull --tag=$(BUILD_TAG) --file=build.Dockerfile .
	docker build --pull \
		--tag=$(TAG) \
		--build-arg=SITE_HOST=$(SITE_HOST) --build-arg=SITE_URL=$(SITE_URL) \
		.

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
push: clean build check
	@ if [ "`git name`" = 'master' ]; then \
		docker push $(BUILD_TAG); \
		docker push $(TAG); \
		IN_MAKEFILE=true git push $(GIT_FLAGS); \
		heroku container:push web \
			--arg=SITE_HOST=$(SITE_HOST),SITE_URL=$(SITE_URL); \
	fi

build/presentations/99-problems.js: src/presentations/99-problems.elm elm-stuff/packages
	elm make --output=$@ $<

node_modules: package.json
	yarn install --frozen-lockfile
	npm rebuild
	touch node_modules

elm-stuff/packages: elm-package.json node_modules
	elm package install -y
