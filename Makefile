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
ELM_DEPENDENCIES = $(wildcard src/NoodleSandwich/*.elm) $(wildcard src/NoodleSandwich/**/*.elm)

ifdef PRODUCTION
ELM_MAKE_FLAGS = --optimize
else
ELM_MAKE_FLAGS =
endif

build: node_modules gulpfile.js $(wildcard src/**/*) $(PRESENTATION_OUTPUT_FILES)
	gulp

.PHONY: clean
clean:
	rm -rf build/*

.PHONY: check
check: lint

.PHONY: lint
lint: node_modules
	yarn run lint

.PHONY: deploy
deploy: deploy-site deploy-assets

.PHONY: hardware
hardware:
	terraform init
	terraform apply

.PHONY: deploy-site
deploy-site: hardware build
	aws s3 sync build s3://noodlesandwich.com --acl=public-read --delete

.PHONY: deploy-assets
deploy-assets: hardware assets
	aws s3 sync assets s3://assets.noodlesandwich.com --acl=public-read --delete

assets:
	aws s3 sync s3://assets.noodlesandwich.com assets

build/talks/%/presentation.js: src/presentations/%.elm $(ELM_DEPENDENCIES)
	elm-format --yes $<
	elm make --output=$@ $(ELM_MAKE_FLAGS) $<

node_modules: package.json
	yarn install --frozen-lockfile
	touch node_modules
