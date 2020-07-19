SHELL := /usr/bin/env bash
PATH := $(PWD)/node_modules/.bin:$(PATH)

TAG = samirtalwar/noodlesandwich.com
ifdef OFFLINE
BUILD_ARGS =
else
BUILD_ARGS = --pull
endif

PRESENTATION_NAMES := 99-problems plz-respect-ur-data teaching-a-machine-to-code teaching-a-machine-to-code-2019
PRESENTATION_OUTPUT_FILES = $(addprefix build/talks/, $(addsuffix /presentation.js, $(PRESENTATION_NAMES)))
ELM_DEPENDENCIES = $(wildcard src/NoodleSandwich/*.elm)
ELM_FILES = $(wildcard src/**/*.elm)
SOURCE_EXTENSIONS := elm js pug scss
SOURCE_FILES = $(foreach ext,$(SOURCE_EXTENSIONS),$(wildcard src/*.$(ext) src/**/*.$(ext)))

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
lint: node_modules $(SOURCE_FILES)
	yarn run lint
	elm-format --validate $(ELM_FILES)

.PHONY: reformat
reformat: node_modules $(SOURCE_FILES)
	elm-format --yes $(ELM_FILES)

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

build/talks/99-problems/presentation.js: src/presentations/NinetyNineProblems.elm $(ELM_DEPENDENCIES)
	elm make --output=$@ $(ELM_MAKE_FLAGS) $<

build/talks/plz-respect-ur-data/presentation.js: src/presentations/PlzRespectUrData.elm $(ELM_DEPENDENCIES)
	elm make --output=$@ $(ELM_MAKE_FLAGS) $<

build/talks/teaching-a-machine-to-code/presentation.js: src/presentations/TeachingAMachineToCode.elm $(ELM_DEPENDENCIES)
	elm make --output=$@ $(ELM_MAKE_FLAGS) $<

build/talks/teaching-a-machine-to-code-2019/presentation.js: src/presentations/TeachingAMachineToCode2019.elm $(ELM_DEPENDENCIES)
	elm make --output=$@ $(ELM_MAKE_FLAGS) $<

node_modules: package.json
	yarn install --frozen-lockfile
	touch node_modules
