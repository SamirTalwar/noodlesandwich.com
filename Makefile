SHELL := /bin/bash
PATH := $(PWD)/node_modules/.bin:$(PATH)

TAG = samirtalwar/noodlesandwich.com
BUILD_TAG = samirtalwar/noodlesandwich.com-build

.PHONY: build
build: node_modules build/presentations/99-problems.js
	docker build --pull --tag=$(BUILD_TAG) --file=build.Dockerfile .
	docker build --pull --tag=$(TAG) .

.PHONY: clean
clean:
	rm -rf build/*
	rm -rf elm-stuff/build-artifacts

.PHONY: check
check: test lint

.PHONY: test
test: node_modules
	yarn run test

.PHONY: lint
lint: node_modules
	yarn run lint

.PHONY: push
push: build check
	@ if [ "`git name`" = 'master' ]; then \
		docker push $(BUILD_TAG); \
		docker push $(TAG); \
		IN_MAKEFILE=true git push $(GIT_FLAGS); \
		heroku container:push web; \
	fi

.PHONY: run
run: build/presentations/99-problems.js
	PORT=8080 ./node_modules/.bin/nodemon -L

build/presentations/99-problems.js: src/presentations/99-problems.elm elm-stuff/packages
	elm make --output=$@ $<

node_modules: package.json
	yarn install --frozen-lockfile
	npm rebuild

elm-stuff/packages: elm-package.json node_modules
	elm package install -y
