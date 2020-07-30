RUNTIME := nodejs12.x
REPO    := techworkerscoalition/twc-site-boston

.PHONY: plan apply sync up clean

package.zip: package.iid
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

package.iid: website/* Dockerfile index.js package*.json
	docker build --build-arg RUNTIME=$(RUNTIME) --iidfile $@ --tag $(REPO) .

.terraform/terraform.zip: package.zip | .terraform
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
