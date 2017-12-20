SHELL := /bin/bash
PATH := $(PWD)/node_modules/.bin:$(PATH)

TAG = samirtalwar/noodlesandwich.com
BUILD_TAG = samirtalwar/noodlesandwich.com-build

build: node_modules gulpfile.js src build/presentations/99-problems.js
	gulp
	docker build --pull --tag=$(BUILD_TAG) --file=build.Dockerfile .
	docker build --pull --tag=$(TAG) .

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
		heroku container:push web; \
	fi

build/presentations/99-problems.js: src/presentations/99-problems.elm elm-stuff/packages
	elm make --output=$@ $<

node_modules: package.json
	yarn install --frozen-lockfile
	npm rebuild

elm-stuff/packages: elm-package.json node_modules
	elm package install -y
