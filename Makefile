TAG = samirtalwar/noodlesandwich.com

.PHONY: build
build:
	docker build --tag=$(TAG) .

.PHONY: check
check: lint

.PHONY: lint
lint:
	npm run lint

.PHONY: push
push: build check
	docker push $(TAG)
	heroku container:push web

.PHONY: run
run: build
	docker run \
		--rm \
		--interactive --tty \
		--publish=8080:8080 \
		--env=PORT=8080 \
		--volume=$$PWD/database.yaml:/usr/src/app/database.yaml \
		--volume=$$PWD/src:/usr/src/app/src \
		samirtalwar/noodlesandwich.com \
		./node_modules/.bin/nodemon -L
