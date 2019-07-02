name    := boston
runtime := nodejs10.x
stages  := build test plan
build   := $(shell git describe --tags --always)
shells  := $(foreach stage,$(stages),shell@$(stage))
digest   = $(shell cat .docker/$(build)@$(1))

.PHONY: all apply clean $(stages) $(shells)

all: package-lock.json package.zip

.docker:
	mkdir -p $@

.docker/$(build)@test: .docker/$(build)@build
.docker/$(build)@plan: .docker/$(build)@test
.docker/$(build)@%: | .docker
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_DEFAULT_REGION \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg RUNTIME=$(runtime) \
	--build-arg TF_VAR_release=$(build) \
	--iidfile $@ \
	--tag techworkersco/$(name):$(build)-$* \
	--target $* .

package-lock.json package.zip: build
	docker run --rm $(call digest,$<) cat $@ > $@

apply: plan .env
	docker run --rm --env-file .env $(call digest,$<)

clean:
	-docker image rm -f $(shell awk {print} .docker/*)
	-rm -rf .docker *.zip

$(stages): %: .docker/$(build)@%

$(shells): shell@%: % .env
	docker run --rm -it --env-file .env $(call digest,$<) /bin/bash
