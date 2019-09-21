name      := boston
runtime   := nodejs10.x
terraform := 0.12.9
stages    := build plan
build     := $(shell git describe --tags --always)
shells    := $(foreach stage,$(stages),shell@$(stage))

.PHONY: all apply clean $(stages) $(shells)

all: package-lock.json package.zip plan

.docker:
	mkdir -p $@

.docker/$(build)@plan: .docker/$(build)@build
.docker/$(build)@%: | .docker
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_DEFAULT_REGION \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg RUNTIME=$(runtime) \
	--build-arg TERRAFORM=$(terraform) \
	--build-arg TF_VAR_release=$(build) \
	--iidfile $@ \
	--tag techworkersco/$(name):$(build)-$* \
	--target $* .

package-lock.json package.zip: .docker/$(build)@build
	docker run --rm --entrypoint cat $(shell cat $<) $@ > $@

apply: .docker/$(build)@plan .env
	docker run --rm --env-file .env $(shell cat $<)

clean:
	-docker image rm -f $(shell awk {print} .docker/*)
	-rm -rf .docker *.zip

$(stages): %: .docker/$(build)@%

$(shells): shell@%: .docker/$(build)@% .env
	docker run --rm -it \
	--entrypoint /bin/sh \
	--env-file .env \
	$(shell cat $<)
