TAG = samirtalwar/noodlesandwich.com

.PHONY: build
build: build/presentations/99-problems.js
	docker build --tag=$(TAG) .

.PHONY: clean
clean:
	rm -rf build/*
	rm -rf elm-stuff/build-artifacts

.PHONY: check
check: lint

.PHONY: lint
lint: node_modules
	npm --silent run lint

.PHONY: push
push: build check
	git push
	docker push $(TAG)
	heroku container:push web

.PHONY: run
run: build
	docker run \
		--rm \
		--interactive --tty \
		--publish=8080:8080 \
		--env=NODE_ENV=$$NODE_ENV \
		--env=PORT=8080 \
		--volume=$$PWD/database.yaml:/usr/src/app/database.yaml \
		--volume=$$PWD/build:/usr/src/app/build \
		--volume=$$PWD/src:/usr/src/app/src \
		samirtalwar/noodlesandwich.com \
		./node_modules/.bin/nodemon -L

build/presentations/99-problems.js: src/presentations/99-problems.elm elm-package.json
	elm make --output=$@ $<

node_modules: package.json
	npm install
