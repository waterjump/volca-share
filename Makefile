.DEFAULT_GOAL := help

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up:  ## Start development server
	docker compose --profile dev up

.PHONY: down
down: ## Stop all containers
	docker compose down

.PHONY: build
build: ## Build docker images
	docker compose build

.PHONY: test
test: ## Run all rails tests
	docker compose --profile test run --rm vs bundle exec rspec

.PHONY: console
console: ## Open a rails console
	docker compose --profile dev exec -it vs bundle exec rails c

.PHONY: ssh
ssh: ## Open a terminal in the application container
	docker compose exec -it vs bash

.PHONY: visit
visit: ## Open the application in a browser
	open http://0.0.0.0:3000
