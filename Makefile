package := $(shell npm pack --dry-run --quiet)

.PHONY: lock build dist

package-lock.json: package.json
	npm install --package-lock-only

lock: package-lock.json

build:
	docker-compose run --rm build cp package*.json /opt/nodejs
	docker-compose run --rm -w /opt/nodejs build

layer.zip: package-lock.json
	docker-compose run --rm -T dist > $@

dist: layer.zip

clean:
	docker-compose down --volumes
