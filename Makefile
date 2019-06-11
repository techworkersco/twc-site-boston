name    := boston
build   := $(shell git describe --tags --always)
runtime := nodejs10.x

.PHONY: all apply clean shell

all: package-lock.json package.lambda.zip package.layer.zip

.docker:
	mkdir -p $@

.docker/%: package.json website | .docker
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_DEFAULT_REGION \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg RUNTIME=$(runtime) \
	--build-arg TF_VAR_release=$* \
	--iidfile $@ \
	--tag techworkersco/$(name):$* .

package-lock.json: .docker/$(build)
	docker run --rm -w /opt/nodejs/ $(shell cat $<) cat $@ > $@

package.lambda.zip package.layer.zip: .docker/$(build)
	docker run --rm -w /var/task/ $(shell cat $<) cat $@ > $@

apply: .docker/$(build)
	docker run --rm $(shell cat $<)

clean:
	-docker image rm -f $(shell sed G .docker/*)
	-rm -rf .docker *.zip

shell: .docker/$(build)
	docker run --rm -it $(shell cat $<) /bin/bash
