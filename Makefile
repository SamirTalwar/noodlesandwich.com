SHELL := /usr/bin/env bash
PATH := $(PWD)/node_modules/.bin:$(PATH)

SOURCE_EXTENSIONS := elm js md pug scss
SOURCE_FILES = $(foreach ext,$(SOURCE_EXTENSIONS),$(wildcard src/*.$(ext) src/**/*.$(ext)))

ELM_PRESENTATION_NAMES := $(shell ./node_modules/.bin/js-yaml database.yaml | jq -r '.talks | .[] | select(.presentation.type == "elm") | .slug')
ELM_PRESENTATION_OUTPUT_FILES = $(addprefix build/talks/, $(addsuffix /presentation.js, $(ELM_PRESENTATION_NAMES)))
ELM_DEPENDENCIES = $(wildcard src/NoodleSandwich/*.elm)
ELM_FILES = $(wildcard src/**/*.elm)

ifdef PRODUCTION
ELM_MAKE_FLAGS = --optimize
else
ELM_MAKE_FLAGS =
endif

build: node_modules gulpfile.js $(wildcard src/**/*) $(ELM_PRESENTATION_OUTPUT_FILES)
	gulp

.PHONY: clean
clean:
	rm -rf build/*

.PHONY: check
check: lint

.PHONY: lint
lint: node_modules $(SOURCE_FILES)
	yarn run lint
	elm-format --validate src

.PHONY: format
format: node_modules $(SOURCE_FILES)
	yarn run format

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

define ELM_PRESENTATION_TEMPLATE =
build/talks/$(1)/presentation.js: $(shell ./node_modules/.bin/js-yaml database.yaml | jq -r --arg name $(1) '.talks | map(select(.slug == $$name)) | first | .presentation.module | gsub("\\."; "/") | ("src/" + . + ".elm")') $$(ELM_DEPENDENCIES)
	elm make --output=$$@ $$(ELM_MAKE_FLAGS) $$<
endef

$(foreach name, $(ELM_PRESENTATION_NAMES), $(eval $(call ELM_PRESENTATION_TEMPLATE,$(name))))

node_modules: package.json
	yarn install --frozen-lockfile
	touch node_modules
