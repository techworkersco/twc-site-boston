REPO      := techworkersco/twc-site-boston
RUNTIME   := nodejs12.x
TERRAFORM := latest
BUILD     := $(shell git describe --tags --always)

package.zip: | node_modules
	zip -r $@ node_modules website index.js package*.json

node_modules: package.json
	npm install

terraform.zip: package.zip | .terraform
	terraform plan -out $@

.env:
	cp $@.example $@

.terraform:
	terraform init

.PHONY: apply clean clobber plan sync up

apply: plan
	terraform $@

clean:
	rm -rf *.zip

clobber: clean
	rm -rf node_modules

plan: terraform.zip

sync:
	aws s3 sync assets s3://boston.techworkerscoalition.org/website/assets/ --acl public-read

up:
	npm start
