NODE_VERSION := 14
REPO         := techworkerscoalition/twc-site-boston

.PHONY: plan apply sync up clean

package.zip: package-lock.json
	docker run --rm --entrypoint cat $$(cat package.iid) $@ > $@

package-lock.json: package.iid
	docker run --rm --entrypoint cat $$(cat package.iid) $@ > $@

package.iid: website/* website/views/* Dockerfile index.js package.json
	docker build --build-arg NODE_VERSION=$(NODE_VERSION) --iidfile $@ --tag $(REPO) .

.terraform/terraform.zip: package.zip *.tf | .terraform
	terraform plan -out $@

.env:
	cp $@.example $@

.terraform:
	terraform init

apply: .terraform/terraform.zip
	terraform apply $<

clean:
	rm -rf .terraform package.iid package.zip

plan: .terraform/terraform.zip

sync:
	aws s3 sync assets s3://boston.techworkerscoalition.org/website/assets/ --acl public-read

up: package.iid .env
	docker run --rm --env-file .env --publish 3000:3000 $$(cat $<)
