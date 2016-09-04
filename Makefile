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
