REPO      := techworkersco/twc-site-boston
RUNTIME   := nodejs12.x
STAGES    := lock dev zip plan
TERRAFORM := latest
BUILD     := $(shell git describe --tags --always)
SHELLS    := $(foreach STAGE,$(STAGES),shell@$(STAGE))

.PHONY: default apply clean clobber sync up $(STAGES) $(SHELLS)

default: package-lock.json package.zip

.docker:
	mkdir -p $@

.docker/lock: package.json
.docker/dev: .docker/lock
.docker/zip: .docker/dev
.docker/plan: .docker/zip
.docker/%: | .docker
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_DEFAULT_REGION \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg RUNTIME=$(RUNTIME) \
	--build-arg TERRAFORM=$(TERRAFORM) \
	--build-arg TF_VAR_BUILD=$(BUILD) \
	--iidfile $@ \
	--tag $(REPO):$* \
	--target $* \
	.

.env:
	cp $@.example $@

package-lock.json package.zip: .docker/zip
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

apply: .docker/plan .env
	docker run --rm \
	--env AWS_ACCESS_KEY_ID \
	--env AWS_DEFAULT_REGION \
	--env AWS_SECRET_ACCESS_KEY \
	$$(cat $<)

clean:
	rm -rf .docker

clobber: clean
	docker image ls --format '{{.Repository}}:{{.Tag}}' $(REPO) | xargs docker image rm --force
	rm package.zip

sync: .docker/lock .env
	docker run --rm \
	--entrypoint aws \
	--env AWS_ACCESS_KEY_ID \
	--env AWS_DEFAULT_REGION \
	--env AWS_SECRET_ACCESS_KEY \
	--volume assets:/var/task/assets \
	$$(cat $<) \
	s3 sync assets s3://boston.techworkerscoalition.org/website/assets/ --acl public-read

up: .docker/dev .env
	docker run --rm -it --entrypoint npm --env-file .env --publish 3000:3000 $$(cat $<) start

$(STAGES): %: .docker/%

$(SHELLS): shell@%: .docker/% .env
	docker run --rm -it --entrypoint /bin/sh --env-file .env $$(cat $<)
