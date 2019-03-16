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
PRESENTATION_OUTPUT_FILES = $(addprefix build/talks/, \
								$(addsuffix /presentation.js, $(PRESENTATION_NAMES)))
ELM_DEPENDENCIES = $(wildcard src/NoodleSandwich/*.elm) $(wildcard src/NoodleSandwich/**/*.elm) \
				   elm-stuff/packages

build: node_modules gulpfile.js $(wildcard src/**/*) $(PRESENTATION_OUTPUT_FILES)
	gulp

.PHONY: clean
clean:
	rm -rf build/*
	rm -rf elm-stuff/build-artifacts/0.18.0/SamirTalwar

.PHONY: check
check: lint

.PHONY: lint
lint: node_modules
	yarn run lint

.PHONY: deploy
deploy: build assets
	terraform init
	terraform apply
	aws s3 sync build s3://noodlesandwich.com --acl=public-read --delete
	aws s3 sync assets s3://assets.noodlesandwich.com --acl=public-read --delete

assets:
	aws s3 sync s3://assets.noodlesandwich.com assets

build/talks/%/presentation.js: src/presentations/%.elm $(ELM_DEPENDENCIES)
	elm-format --yes $<
	elm make --warn --output=$@ $<

node_modules: package.json
	yarn install --frozen-lockfile
	npm rebuild
	touch node_modules

elm-stuff/packages: elm-package.json node_modules
	elm package install -y
	touch $@
