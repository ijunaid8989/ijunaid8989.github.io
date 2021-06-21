default: help

all: install build


help: ## Show the commands and help
	@grep -E '^[a-zA-Z_ -]+:' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


install: ## Install dependencies
	which ruby || asdf install
	which bundle || gem install bundler

	bundle config set --local path vendor/bundle
	bundle install

s start: ## Start development server at port 4444
	bundle exec jekyll server --livereload --watch --future --port 4444

build: ## Production build
	JEKYLL_ENV=production bundle exec jekyll build --trace
