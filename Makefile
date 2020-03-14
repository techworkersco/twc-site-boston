REPO      := techworkersco/twc-site-boston
RUNTIME   := nodejs12.x
STAGES    := build plan
TERRAFORM := latest
BUILD     := $(shell git describe --tags --always)
SHELLS    := $(foreach STAGE,$(STAGES),shell@$(STAGE))

.PHONY: default apply clean clobber sync up $(STAGES) $(SHELLS)

default: package-lock.json package.zip

.docker:
	mkdir -p $@

.docker/build: package.json
.docker/plan:  .docker/build
.docker/%:   | .docker
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_DEFAULT_REGION \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg RUNTIME=$(RUNTIME) \
	--build-arg TERRAFORM=$(TERRAFORM) \
	--build-arg TF_VAR_RELEASE=$(BUILD) \
	--iidfile $@ \
	--tag $(REPO):$* \
	--target $* \
	.

.env:
	cp $@.example $@

package-lock.json package.zip: .docker/build
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

apply: .docker/plan .env
	docker run --rm --env-file .env $$(cat $<)

clean:
	rm -rf .docker

clobber: clean
	docker image ls --format '{{.Repository}}:{{.Tag}}' $(REPO) | xargs docker image rm --force

sync: .docker/build .env
	docker run --rm --entrypoint aws --env-file .env $$(cat $<) \
	s3 sync assets s3://boston.techworkerscoalition.org/website/assets/ --acl public-read

up: .docker/build .env
	docker run --rm -it --entrypoint npm --env-file .env --publish 3000:3000 $$(cat $<) start

$(STAGES): %: .docker/%

$(SHELLS): shell@%: .docker/% .env
	docker run --rm -it --entrypoint /bin/sh --env-file .env $$(cat $<)
